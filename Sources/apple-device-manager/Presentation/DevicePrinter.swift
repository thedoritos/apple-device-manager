import Foundation

struct DevicePrinter {
    func print(_ device: Device) {
        let id = device.id
        let status = device.attributes.status.rawValue.first ?? "N"
        let date = device.attributes.addedDate
        let name = device.attributes.name

        Swift.print("\(id) \(status) \(date) \"\(name)\"")
    }

    func print(_ devices: [Device]) {
        devices.forEach(print(_:))
    }
}
