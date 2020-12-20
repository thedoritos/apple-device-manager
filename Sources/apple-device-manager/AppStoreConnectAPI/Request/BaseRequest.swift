import Foundation
#if os(Linux)
import FoundationNetworking
#endif

protocol BaseRequest: Request {
    var token: APIToken { get }
}

extension BaseRequest {
    var baseURL: URL { return URL(string: "https://api.appstoreconnect.apple.com/v1/")! }

    func intercept(urlRequest: URLRequest) throws -> URLRequest {
        var mutableRequest = urlRequest
        mutableRequest.addValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let response = object as? Response else {
            throw ResponseError.unexpectedObject(object)
        }
        return response
    }
}

extension BaseRequest where Response: Decodable {
    var dataParser: DataParser { return DecodableDataParser<Response>() }
}

struct DecodableDataParser<T: Decodable>: DataParser {
    let contentType: String? = "application/json"

    func parse(data: Data) throws -> Any {
        let decoder = JSONDecoder()
        let dateDecoder = ISO8601DateFormatter()
        dateDecoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom() {
            let container = try $0.singleValueContainer()
            let dateString = try container.decode(String.self)
            return dateDecoder.date(from: dateString)!
        }

        return try decoder.decode(T.self, from: data)
    }
}
