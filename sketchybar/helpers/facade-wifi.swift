import AppKit
import CoreLocation
import CoreWLAN
import Foundation

struct Networks: Encodable {
    let connected: Bool
    let current: String?
    let nearby: [String]
    let permission: String
}

final class NetworkReader: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let destination: URL
    private let request: Bool
    private var finished = false

    init(destination: URL, request: Bool) {
        self.destination = destination
        self.request = request
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        manager.delegate = self
        if request && manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in self?.finish() }
        } else {
            finish()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        let status = manager.authorizationStatus
        let authorized = status == .authorizedAlways
        let permission = authorized ? "granted" : status == .notDetermined ? "required" : "unavailable"
        let interface = CWWiFiClient.shared().interface()
        let connected = interface?.interfaceMode() == .station
        let current = interface?.ssid()
        var seen = Set(current.map { [$0] } ?? [])
        var nearby = [String]()
        if authorized, let interface, interface.powerOn() {
            let scanned = (try? interface.scanForNetworks(withName: nil)) ?? []
            for network in scanned.sorted(by: { $0.rssiValue > $1.rssiValue }) {
                if let name = network.ssid, !name.isEmpty, seen.insert(name).inserted {
                    nearby.append(name)
                }
                if nearby.count == 6 { break }
            }
        }
        let value = Networks(connected: connected, current: current, nearby: nearby, permission: permission)
        if let result = try? JSONEncoder().encode(value) { try? result.write(to: destination) }
        NSApplication.shared.terminate(nil)
    }
}

guard CommandLine.arguments.count >= 2 else { exit(1) }
let result = URL(fileURLWithPath: CommandLine.arguments[1])
let delegate = NetworkReader(destination: result, request: CommandLine.arguments.dropFirst(2).first == "request")
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
