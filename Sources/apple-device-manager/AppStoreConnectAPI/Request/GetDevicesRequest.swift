import Foundation

struct GetDeivcesRequest: BaseRequest {
    typealias Response = DevicesResopnse

    let method: HTTPMethod = .get
    let path: String = "devices"

    let token: APIToken
}
