import CoreWLAN
import Foundation

guard let interface = CWWiFiClient.shared().interface(), interface.powerOn() else { exit(0) }
let current = interface.ssid()
let scanned = (try? interface.scanForNetworks(withName: nil)) ?? []
var seen = Set<String>()
var names = [String]()
if let current {
    names.append("● " + current)
    seen.insert(current)
}
for network in scanned.sorted(by: { $0.rssiValue > $1.rssiValue }) {
    if let name = network.ssid, !name.isEmpty, seen.insert(name).inserted {
        names.append(name)
    }
}
let data = try JSONEncoder().encode(Array(names.prefix(5)))
FileHandle.standardOutput.write(data)
