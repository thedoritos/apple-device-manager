import APIKit

/// https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
struct PatchDevicesRequest: BaseRequest {
    typealias Response = DeviceResopnse

    let method: HTTPMethod = .patch
    var path: String { "devices/\(body.id)" }

    let token: APIToken
    let body: DeviceUpdateRequest

    var bodyParameters: BodyParameters? {
        guard let json = body.asJSON() else { return nil }
        return JSONBodyParameters.init(JSONObject: json)
    }
}
