import CoreAudio
import Foundation

func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                               mElement: kAudioObjectPropertyElementMain)
}

func number(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
    var property = address(selector)
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout.size(ofValue: value))
    return AudioObjectGetPropertyData(object, &property, 0, nil, &size, &value) == noErr ? value : nil
}

func string(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
    var property = address(selector)
    var value: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout.size(ofValue: value))
    guard AudioObjectGetPropertyData(object, &property, 0, nil, &size, &value) == noErr,
          let value else { return nil }
    return value.takeRetainedValue() as String
}

func outputIcon() -> String {
    guard let device = number(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice),
          let transport = number(device, kAudioDevicePropertyTransportType) else { return "bluetooth" }
    let name = string(device, kAudioObjectPropertyName) ?? ""
    let model = string(device, kAudioDevicePropertyModelUID) ?? ""
    if name.localizedCaseInsensitiveContains("AirPods") || model.localizedCaseInsensitiveContains("AirPods") {
        return name.localizedCaseInsensitiveContains("Max") ? "headphones" : "airpods"
    }
    if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
        || name.localizedCaseInsensitiveContains("headphones") || name.localizedCaseInsensitiveContains("headset") {
        return "headphones"
    }
    return "bluetooth"
}

print(outputIcon())
