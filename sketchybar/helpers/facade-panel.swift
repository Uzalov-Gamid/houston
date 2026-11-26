import AppKit
import SwiftUI

private let ink = Color(red: 0.95, green: 0.91, blue: 0.86)
private let muted = Color(red: 0.70, green: 0.62, blue: 0.56)
private let copper = Color(red: 0.88, green: 0.69, blue: 0.53)
private let blue = Color(red: 0.40, green: 0.61, blue: 0.77)
private let panelBorder = Color.white.opacity(0.12)

private struct Track: Decodable {
    let title: String?
    let bundleIdentifier: String?
    let mediaType: String?
    let artist: String?
    let artworkData: String?
    let elapsedTime: Double?
    let elapsedTimeNow: Double?
    let duration: Double?
    let playing: Bool?
    let playbackRate: Double?

    var isVideo: Bool { mediaType == "MRMediaRemoteMediaTypeVideo" }
    var displayTitle: String { title.flatMap { $0.isEmpty ? nil : $0 } ?? (isVideo ? "Video" : "Active media") }
    var seekDuration: Double? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        return duration
    }

    func matches(_ other: Track?) -> Bool {
        title == other?.title && artist == other?.artist && bundleIdentifier == other?.bundleIdentifier
    }
}

private struct Notice: Decodable {
    let app: String
    let title: String
    let time: String
    let kind: String?
}

private struct NoticeReport: Decodable {
    let readable: Bool
    let items: [Notice]
}

@MainActor
private final class PanelModel: ObservableObject {
    @Published var track: Track?
    @Published var cover: NSImage?
    @Published var notices: [Notice] = []
    @Published var noticeAccess = true
    private var sampledAt = Date()
    private var refreshing = false
    private var commandRunning = false
    private let media = "/opt/homebrew/bin/media-control"

    private nonisolated static func run(_ executable: String, _ arguments: [String]) async -> Data {
        await Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            guard (try? process.run()) != nil else { return Data() }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return process.terminationStatus == 0 ? data : Data()
        }.value
    }

    func refresh() async {
        if refreshing { return }
        refreshing = true
        defer { refreshing = false }
        let data = await Self.run(media, ["get", "--no-artwork", "--allow-missing-title", "--now"])
        let next = try? JSONDecoder().decode(Track.self, from: data)
        let changed = next.map { !$0.matches(track) } ?? (track != nil)
        track = next
        sampledAt = Date()
        if changed { cover = nil }
        if changed, let next {
            let artwork = await Self.run(media, ["get", "--allow-missing-title"])
            if let detailed = try? JSONDecoder().decode(Track.self, from: artwork),
               detailed.matches(next),
               let encoded = detailed.artworkData, let bytes = Data(base64Encoded: encoded) {
                cover = NSImage(data: bytes)
            }
        }
    }

    private var noticeHelper: String {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            ".config/sketchybar/helpers/facade-notifications.py"
        ).path
    }

    func acknowledgeNotices() async {
        _ = await Self.run("/opt/homebrew/bin/python3", [noticeHelper, "--seen"])
        _ = await Self.run("/opt/homebrew/bin/sketchybar", ["--trigger", "facade_panel_seen"])
    }

    func loadSnapshot(_ path: String) {
        let file = URL(fileURLWithPath: path).standardizedFileURL
        let directory = FileManager.default.temporaryDirectory.standardizedFileURL.path
        guard file.deletingLastPathComponent().path == directory,
              file.lastPathComponent.hasPrefix("facade-panel-notices.") else { return }
        if let data = try? Data(contentsOf: file),
           let report = try? JSONDecoder().decode(NoticeReport.self, from: data) {
            notices = report.items
            noticeAccess = report.readable
        }
        try? FileManager.default.removeItem(at: file)
    }

    func loadNotices() async {
        let data = await Self.run("/opt/homebrew/bin/python3", [noticeHelper])
        let report = try? JSONDecoder().decode(NoticeReport.self, from: data)
        if let report {
            if report.readable {
                notices = report.items
            } else {
                let system = notices.filter { $0.kind == nil }
                notices = report.items + system
            }
            noticeAccess = report.readable || !notices.isEmpty
        }
    }

    func elapsed(at date: Date) -> Double {
        guard let track else { return 0 }
        let offset = track.playing == true ? max(0, date.timeIntervalSince(sampledAt)) * (track.playbackRate ?? 1) : 0
        return min(track.seekDuration ?? .greatestFiniteMagnitude, max(0, (track.elapsedTimeNow ?? track.elapsedTime ?? 0) + offset))
    }

    func send(_ command: String, value: Double? = nil) {
        if commandRunning { return }
        commandRunning = true
        Task {
            let arguments = [command] + (value.map { [String(format: "%.2f", $0)] } ?? [])
            _ = await Self.run(media, arguments)
            try? await Task.sleep(for: .milliseconds(150))
            commandRunning = false
            await refresh()
        }
    }
}

private struct WaveRail: View {
    let fraction: Double
    let title: String
    let seek: ((Double) -> Void)?
    @State private var drag: Double?

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let samples = max(20, Int(size.width / 4))
                let frame = size.width / CGFloat(samples)
                let seed = title.utf8.reduce(UInt32(19)) { ($0 &* 31) &+ UInt32($1) }
                var state = seed
                for index in 0..<samples {
                    state = state &* 1664525 &+ 1013904223
                    let sample = Double((state >> 16) & 255) / 255
                    let envelope = 0.56 + 0.35 * sin(Double(index) / Double(samples) * .pi)
                    let height = CGFloat(4 + sample * 19 * envelope)
                    let rect = CGRect(x: frame * CGFloat(index), y: (size.height - height) * 0.5,
                                      width: max(1, frame - 1.5), height: height)
                    let played = Double(index) / Double(samples) < (drag ?? fraction)
                    context.fill(Path(roundedRect: rect, cornerRadius: 1),
                                 with: .color(played ? copper : muted.opacity(0.34)))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                guard seek != nil else { return }
                drag = max(0, min(1, event.location.x / max(1, geometry.size.width)))
            }.onEnded { _ in
                if let drag { seek?(drag) }
                drag = nil
            })
        }
        .frame(height: 28)
        .accessibilityLabel("Playback position")
        .accessibilityValue("\(Int(fraction * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: seek?(min(1, fraction + 0.05))
            case .decrement: seek?(max(0, fraction - 0.05))
            @unknown default: break
            }
        }
    }
}

private struct Dashboard: View {
    @ObservedObject var model: PanelModel
    let width: CGFloat
    private let noticeHeight: CGFloat = 43

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            player
            Rectangle().fill(panelBorder).frame(height: 1)
            inbox
        }
        .padding(16)
        .frame(width: width, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.12, green: 0.09, blue: 0.08).opacity(0.97))
            RoundedRectangle(cornerRadius: 16).strokeBorder(panelBorder, lineWidth: 1)
        }
        .foregroundStyle(ink)
        .font(.system(size: 12, design: .monospaced))
        .preferredColorScheme(.dark)
        .task {
            async let player: () = model.refresh()
            async let inbox: () = model.loadNotices()
            _ = await (player, inbox)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                if Task.isCancelled { break }
                await model.refresh()
                await model.loadNotices()
            }
        }
    }

    private func timeLabel(_ seconds: Double) -> String {
        let rounded = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", rounded / 60, rounded % 60)
    }

    private var player: some View {
        let track = model.track
        let title = track?.displayTitle
        let duration = track?.seekDuration ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07))
                    if let cover = model.cover {
                        Image(nsImage: cover).resizable().scaledToFill()
                    } else {
                        Image(systemName: track?.isVideo == true ? "film" : "music.note").font(.system(size: 21, weight: .medium)).foregroundStyle(copper)
                    }
                }
                .frame(width: 55, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Now playing").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(copper)
                    Text(title ?? "No active media")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                    if let artist = model.track?.artist, !artist.isEmpty {
                        Text(artist).lineLimit(1).foregroundStyle(muted)
                    }
                }
                Spacer(minLength: 0)
            }

            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let time = model.elapsed(at: timeline.date)
                HStack(spacing: 8) {
                    WaveRail(fraction: duration > 0 ? time / duration : 0, title: title ?? "",
                             seek: duration > 0 ? { model.send("seek", value: $0 * duration) } : nil)
                    Text(duration > 0 ? timeLabel(time) + " / " + timeLabel(duration) : "—")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(muted)
                        .monospacedDigit()
                }
                .disabled(title == nil)
                .opacity(title == nil ? 0.5 : 1)
            }
        }
    }

    private func noticeRow(_ notice: Notice) -> some View {
        let icon: String
        switch notice.kind {
        case "approval": icon = "exclamationmark.bubble"
        case "complete": icon = "checkmark.circle"
        default: icon = "bell"
        }
        return HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(notice.kind == nil ? muted : blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.title.isEmpty ? notice.app : notice.title).fontWeight(.medium).lineLimit(1)
                if !notice.title.isEmpty {
                    Text(notice.app).font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).lineLimit(1)
                }
            }
            Spacer(minLength: 5)
            Text(notice.time).font(.system(size: 10, design: .monospaced)).foregroundStyle(muted)
        }
        .padding(.trailing, 9)
        .frame(height: noticeHeight)
        .overlay(alignment: .bottom) { Rectangle().fill(panelBorder.opacity(0.65)).frame(height: 1) }
    }

    private var inbox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notifications").fontWeight(.semibold)
                Spacer()
                if !model.notices.isEmpty {
                    Text(model.notices.count.formatted()).foregroundStyle(muted).accessibilityLabel("Notification count")
                }
            }

            if model.notices.isEmpty {
                Text(model.noticeAccess ? "No recent notifications" : "Notifications unavailable")
                    .foregroundStyle(muted).frame(height: 26, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(model.notices.enumerated()), id: \.offset) { _, notice in
                            noticeRow(notice)
                        }
                    }
                }
                .scrollIndicators(model.notices.count > 4 ? .visible : .hidden)
                .frame(height: CGFloat(min(model.notices.count, 4)) * noticeHeight)
            }
        }
    }
}

private final class Overlay: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { NSApplication.shared.terminate(nil) }
}

@MainActor
private final class PanelDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = PanelModel()
    var panel: Overlay?
    var host: NSHostingView<Dashboard>?
    var change: Any?
    var mouseMonitor: Any?
    var screen: NSScreen?
    var anchorX: CGFloat = 0
    var clockX: CGFloat = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let argv = CommandLine.arguments
        let display = argv.count > 1 ? UInt32(argv[1]) : nil
        if argv.count > 3 { model.loadSnapshot(argv[3]) }
        let requestedX = argv.count > 2 ? Double(argv[2]) : nil
        let screenKey = NSDeviceDescriptionKey("NSScreenNumber")
        guard let current = NSScreen.screens.first(where: {
            ($0.deviceDescription[screenKey] as? NSNumber)?.uint32Value == display
        }) ?? NSScreen.main else { NSApp.terminate(nil); return }
        screen = current
        let hasNotch = current.safeAreaInsets.top > 0
        clockX = requestedX ?? current.frame.midX
        anchorX = hasNotch ? current.frame.midX : clockX
        let width: CGFloat = hasNotch ? 438 : 360
        let body = NSHostingView(rootView: Dashboard(model: model, width: width))
        host = body
        let window = Overlay(contentRect: NSRect(x: 0, y: 0, width: width, height: 215),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel = window
        window.delegate = self
        window.contentView = body
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .popUpMenu
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        change = model.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.place() }
        }
        place()
        window.makeKeyAndOrderFront(nil)
        Task { await model.acknowledgeNotices() }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, let panel = self.panel, let screen = self.screen else { return }
                let location = NSEvent.mouseLocation
                let overClock = screen.frame.contains(location) && location.y > screen.frame.maxY - 38
                    && abs(location.x - self.clockX) <= 70
                if !panel.frame.contains(location) && !overClock { NSApp.terminate(nil) }
            }
        }
    }

    private func place() {
        guard let panel, let host, let screen else { return }
        let size = host.fittingSize
        let limits = screen.visibleFrame.insetBy(dx: 6, dy: 0)
        let x = max(limits.minX, min(anchorX - size.width / 2, limits.maxX - size.width))
        let y = screen.frame.maxY - max(screen.safeAreaInsets.top, 38) - 7 - size.height
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if panel?.isVisible == true { NSApp.terminate(nil) }
        return false
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = PanelDelegate()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
}
