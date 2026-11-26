// input-source — switch the keyboard layout from the command line.
//
//   input-source                            # print the current layout id
//   input-source com.apple.keylayout.ABC    # switch to it
//   input-source --ghostty-window ID       # switch only if the window belongs to Ghostty
//
// Built by install.sh into ~/.local/bin/input-source:
//   swiftc -O ~/.config/aerospace/input-source.swift -o ~/.local/bin/input-source
import AppKit
import Carbon

let args = Array(CommandLine.arguments.dropFirst())
guard let choice = args.first else {
    let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let id = Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(current, kTISPropertyInputSourceID)).takeUnretainedValue()
    print(id)
    exit(0)
}

let wanted: String
if choice == "--ghostty-window" {
    guard args.count == 2, let window = CGWindowID(args[1]),
          let info = (CGWindowListCopyWindowInfo(.optionIncludingWindow, window) as? [[String: Any]])?.first,
          let pid = info[kCGWindowOwnerPID as String] as? pid_t,
          NSRunningApplication(processIdentifier: pid)?.bundleIdentifier == "com.mitchellh.ghostty"
    else { exit(0) }
    wanted = "com.apple.keylayout.ABC"
} else {
    wanted = choice
}

let filter = [kTISPropertyInputSourceID as String: wanted] as CFDictionary
guard let sources = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource],
      let source = sources.first else {
    FileHandle.standardError.write("input-source: no layout \(wanted)\n".data(using: .utf8)!)
    exit(1)
}
exit(TISSelectInputSource(source) == noErr ? 0 : 1)
