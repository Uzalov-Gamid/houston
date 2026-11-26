#!/usr/bin/python3
"""Record local Codex events without retaining hook or notification payloads."""

from datetime import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid


STATE = Path.home() / ".local" / "state" / "sketchybar" / "agent-alerts.json"
BAR = "/opt/homebrew/bin/sketchybar"
SOUNDS = {
    "complete": "/System/Library/Sounds/Glass.aiff",
    "approval": "/System/Library/Sounds/Pop.aiff",
}
TITLES = {
    "complete": "Turn complete",
    "approval": "Approval needed in Codex",
}
MAX_ITEMS = 40


def publish(kind, event_id, state=STATE):
    now = datetime.now().astimezone()
    alert = {
        "app": "Codex",
        "title": TITLES[kind],
        "time": now.strftime("%H:%M"),
        "epoch": now.timestamp(),
        "id": event_id,
        "kind": kind,
    }

    state.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    lock = os.open(state.with_suffix(".lock"), os.O_CREAT | os.O_RDWR, 0o600)
    with os.fdopen(lock, "r+") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            stored = json.loads(state.read_text(encoding="utf-8"))
        except (FileNotFoundError, UnicodeDecodeError, json.JSONDecodeError):
            stored = {}
        items = stored.get("items") if isinstance(stored, dict) else None
        items = [item for item in items if isinstance(item, dict)] if isinstance(items, list) else []
        if any(item.get("id") == event_id for item in items):
            return False

        items = [alert, *items[:MAX_ITEMS - 1]]
        with tempfile.NamedTemporaryFile(mode="w", dir=state.parent, encoding="utf-8", delete=False) as tmp:
            tmp_path = Path(tmp.name)
            try:
                json.dump({"items": items}, tmp, ensure_ascii=False)
                tmp.close()
                os.replace(tmp_path, state)
            finally:
                tmp_path.unlink(missing_ok=True)
    return True


def dispatch(kind):
    for command in ([BAR, "--trigger", "facade_agent_notice"], ["/usr/bin/afplay", SOUNDS[kind]]):
        try:
            subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except OSError:
            # A missing UI or sound utility must not affect the Codex operation.
            pass


def record(kind, payload):
    if kind == "complete":
        if payload.get("type") != "agent-turn-complete":
            return
        thread_id, turn_id = payload.get("thread-id"), payload.get("turn-id")
        if isinstance(thread_id, str) and isinstance(turn_id, str):
            identity = hashlib.sha256((thread_id + "\0" + turn_id).encode("utf-8")).hexdigest()[:24]
        else:
            identity = uuid.uuid4().hex
    else:
        if payload.get("hook_event_name") != "PermissionRequest":
            return
        identity = uuid.uuid4().hex
    if publish(kind, identity):
        dispatch(kind)


def main(argv):
    if not argv or argv[0] not in TITLES:
        return
    kind, *arguments = argv
    try:
        payload = json.loads(arguments[-1]) if kind == "complete" and arguments else json.load(sys.stdin)
        if isinstance(payload, dict):
            record(kind, payload)
    except (OSError, UnicodeError, ValueError):
        # Keep notification errors out of the hook protocol.
        pass
    if kind == "complete" and len(arguments) >= 2:
        try:
            os.execv(arguments[0], arguments)
        except OSError:
            pass
    # A PermissionRequest hook returns quietly to the normal approval prompt.


if __name__ == "__main__":
    main(sys.argv[1:])
