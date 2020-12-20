import Foundation
#if os(Linux)
import FoundationNetworking
#endif

protocol Request {
    associatedtype Response

    var method: HTTPMethod { get }
    var baseURL: URL { get }
    var path: String { get }

    var dataParser: DataParser { get }
    var bodyParameters: BodyParameters? { get }

    func intercept(urlRequest: URLRequest) throws -> URLRequest
}

extension Request {
    var bodyParameters: BodyParameters? { nil }
}

enum HTTPMethod: String {
    case get = "GET"
    case patch = "PATCH"

    var string: String { self.rawValue }
}

protocol DataParser {
    var contentType: String? { get }

    func parse(data: Data) throws -> Any
}

protocol BodyParameters {
    var JSONObject: [String: Any] { get }
}

struct JSONBodyParameters: BodyParameters {
    let JSONObject: [String : Any]
}

enum ResponseError: Error {
    case unexpectedObject(_ object: Any)
    case emptyObject
}

enum CallbackQueue {
    case sessionQueue

    public func execute(closure: @escaping () -> Void) {
        switch self {
            case .sessionQueue:
                closure()
        }
    }
}

enum Result<T: Request> {
    case success(_ response: T.Response)
    case failure(_ error: Error)
}

struct Session {
    static func send<T: Request>(_ request: T, callbackQueue: CallbackQueue, handler: @escaping (Result<T>) -> Void) {
        let url = request.baseURL.appendingPathComponent(request.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.string

        if let contentType = request.dataParser.contentType {
            urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let bodyParameters = request.bodyParameters {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters.JSONObject, options: [])
        }

        if let intercepted = try? request.intercept(urlRequest: urlRequest) {
            urlRequest = intercepted
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse ,error) in
            guard
                let data = data,
                let parsedResponse = try? request.dataParser.parse(data: data) as? T.Response
            else {
                callbackQueue.execute { handler(.failure(ResponseError.emptyObject)) }
                return
            }

            callbackQueue.execute { handler(.success(parsedResponse)) }
        }

        task.resume()
    }
}
