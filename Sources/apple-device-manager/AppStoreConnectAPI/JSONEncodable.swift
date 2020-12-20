import Foundation

protocol JSONEncodable: Encodable {}

extension JSONEncodable {
    func asJSON() -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let dateEncoder = ISO8601DateFormatter()
        dateEncoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let dateString = dateEncoder.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }

        guard
            let data = try? encoder.encode(self),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return nil }

        return json
    }
}

extension Array where Element == JSONEncodable? {
    func asJSON() -> [String: Any]? {
        let elements = self.compactMap { $0?.asJSON() }
        if elements.count == 0 { return nil }
        return elements.reduce([String: Any]()) { acc, element in
            acc.merging(element, uniquingKeysWith: { _, new in new })
        }
    }
}
