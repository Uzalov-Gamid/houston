"""Read a few recent, still-delivered notification titles for the local popup."""

from pathlib import Path
import json
import plistlib
import sqlite3
import sys
import tempfile
import time


DATABASE = Path.home() / "Library/Group Containers/group.com.apple.usernoted/db2/db"
APPLE_EPOCH = 978307200
STATE = Path.home() / ".local/state/sketchybar"
AGENT = STATE / "agent-alerts.json"
SEEN = STATE / "notifications-seen"
APP_NAMES = {
    "com.apple.MobileSMS": "Messages",
    "com.apple.mail": "Mail",
    "com.apple.iCal": "Calendar",
    "com.apple.reminders": "Reminders",
    "ru.keepcoder.Telegram": "Telegram",
    "com.tinyspeck.slackmacgap": "Slack",
    "com.TickTick.task.mac": "TickTick",
}


def recent_notifications():
    cutoff = time.time() - APPLE_EPOCH - 86400
    with sqlite3.connect(DATABASE.as_uri() + "?mode=ro", uri=True, timeout=0.15) as db:
        rows = db.execute(
            """SELECT app.identifier, record.uuid, record.data, record.delivered_date,
                      delivered.list
               FROM record
               JOIN app USING (app_id)
               JOIN delivered USING (app_id)
               WHERE record.delivered_date >= ?
               ORDER BY record.delivered_date DESC
               LIMIT 50""",
            (cutoff,),
        ).fetchall()
    selected = []
    for identifier, uuid, data, delivered_at, delivered in rows:
        if not delivered or not uuid or not data:
            continue
        if not any(delivered[i:i + 16] == uuid for i in range(0, len(delivered), 16)):
            continue
        try:
            request = plistlib.loads(data).get("req", {})
        except (ValueError, TypeError, plistlib.InvalidFileException):
            continue
        if not isinstance(request, dict):
            continue
        title = request.get("titl")
        label = APP_NAMES.get(identifier, identifier.rsplit(".", 1)[-1])
        timestamp = time.strftime("%H:%M", time.localtime(APPLE_EPOCH + delivered_at))
        selected.append({
            "app": label, "title": title if isinstance(title, str) else "", "time": timestamp,
            "epoch": APPLE_EPOCH + delivered_at,
        })
    return selected


def agent_notifications():
    try:
        value = json.loads(AGENT.read_text())
        items = value.get("items", [])
        return [item for item in items if isinstance(item, dict) and isinstance(item.get("epoch"), (int, float))]
    except (OSError, ValueError, AttributeError):
        return []


def last_seen():
    try:
        return float(SEEN.read_text())
    except (OSError, ValueError):
        return 0


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "--seen":
        STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
        with tempfile.NamedTemporaryFile(mode="w", dir=STATE, delete=False) as marker:
            marker.write(str(time.time()))
        Path(marker.name).replace(SEEN)
        return
    try:
        system = recent_notifications()
        readable = True
    except (OSError, sqlite3.Error):
        system, readable = [], False
    items = sorted(agent_notifications() + system, key=lambda item: item["epoch"], reverse=True)
    if mode == "--unread":
        print(json.dumps({"unread": bool(items and items[0]["epoch"] > last_seen())}))
    else:
        print(json.dumps({"readable": readable, "items": items[:40]}))


if __name__ == "__main__":
    main()
