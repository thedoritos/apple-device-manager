import Foundation

struct Device: Decodable {
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable {
        let deviceClass: DeviceClass
        let model: String?
        let name: String
        let platform: BundleIdPlatform
        let status: DeviceStatus
        let udid: String
        let addedDate: Date
    }
}

enum DeviceStatus: String, Decodable {
    case enabled = "ENABLED"
    case disabled = "DISABLED"
}

enum DeviceClass: String, Decodable {
    case appleWatch = "APPLE_WATCH"
    case iPad = "IPAD"
    case iPhone = "IPHONE"
    case iPod = "IPOD"
    case appleTV = "APPLE_TV"
    case mac = "MAC"
}

enum BundleIdPlatform: String, Decodable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
}
