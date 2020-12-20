import Foundation
import JWTKit

struct APIToken {
    let value: String
    let expiration: Date

    struct Payload: JWTPayload {
        /// Your issuer ID from the API Keys page in App Store Connect (Ex: 57246542-96fe-1a63-e053-0824d011072a)
        var iss: IssuerClaim

        /// The token's expiration time, in Unix epoch time; tokens that expire more than 20 minutes in the future are not valid (Ex: 1528408800)
        var exp: ExpirationClaim

        var aud: AudienceClaim = .init(value: "appstoreconnect-v1")

        func verify(using signer: JWTSigner) throws {
            try self.exp.verifyNotExpired()
        }
    }

    static func encode(_ key: APIKey) throws -> APIToken {
        let expiration = Date().addingTimeInterval(20 * 60)
        let payload = Payload(iss: .init(value: key.issuerId), exp: .init(value: expiration))
        let signer = try JWTSigner.es256(key: .private(pem: key.value))
        let jwt = try signer.sign(payload, kid: .init(string: key.id))

        return APIToken(value: jwt, expiration: expiration)
    }
}
