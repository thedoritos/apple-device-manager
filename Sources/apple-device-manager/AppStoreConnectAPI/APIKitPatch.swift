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
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response
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

enum SessionTaskError: Error {
    case connectionError(Error)
    case responseError(Error)

    /// Error for programming issues. Likely to not happen.
    case undefined
}

enum ResponseError: Error {
    case nonHTTPURLResponse(URLResponse?)
    case unacceptableStatusCode(Int)
    case unexpectedObject(Any)
}

enum Result<T: Request> {
    case success(_ response: T.Response)
    case failure(_ error: SessionTaskError)
}

struct Session {
    static func send<T: Request>(_ request: T) -> Result<T> {
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

        var result: Result<T> = .failure(.undefined)

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse ,error) in
            switch (data, urlResponse, error) {
                case (_, _, let error?):
                    result = .failure(.connectionError(error))

                case (let data?, let urlResponse as HTTPURLResponse, _):
                    if 200..<300 ~= urlResponse.statusCode {
                        do {
                            let parsed = try request.dataParser.parse(data: data)
                            let response = try request.response(from: parsed, urlResponse: urlResponse)
                            result = .success(response)
                        } catch {
                            result = .failure(.responseError(error))
                        }
                    } else {
                        result = .failure(.responseError(ResponseError.unacceptableStatusCode(urlResponse.statusCode)))
                    }

                default:
                    result = .failure(.responseError(ResponseError.nonHTTPURLResponse(urlResponse)))
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        return result
    }
}
