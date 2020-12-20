import Foundation

struct DeviceUpdateRequest: JSONEncodable {
    let data: Data

    var id: String { return data.id }

    struct Data: Encodable {
        let attributes: Attributes
        let id: String
        let type: String = "devices"

        struct Attributes: Encodable {
            let name: String?
            let status: DeviceStatus?

            init(name: String? = nil, status: DeviceStatus? = nil) {
                self.name = name
                self.status = status
            }
        }
    }
}
