import Foundation
import ArgumentParser
import APIKit

struct AppleDeviceManager: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "adm",
        abstract: "Apple Device Manager",
        subcommands: [List.self]
    )
}

extension AppleDeviceManager {
    struct Options: ParsableArguments {
        @Option(help: "Path to the private key.", completion: .file(extensions: [".p8"]))
        var keyPath: String

        @Option(help: "Id of the private key.")
        var keyId: String

        @Option(help: "Id of the issuer of private key.")
        var issuerId: String

        func getKey() throws -> APIKey {
            let keyValue = try String(contentsOfFile: keyPath)
            return APIKey(id: keyId, issuerId: issuerId, value: keyValue)
        }
    }

    struct List: ParsableCommand {
        @OptionGroup var baseOptions: Options

        mutating func run() throws {
            let key = try baseOptions.getKey()
            let token = try APIToken.encode(key)

            let semaphore = DispatchSemaphore(value: 0)
            Session.send(GetDeivcesRequest(token: token), callbackQueue: .sessionQueue) { result in
                switch result {
                    case .success(let response):
                        print(response)
                        semaphore.signal()
                    case .failure(let error):
                        AppleDeviceManager.exit(withError: error)
                }
            }
            semaphore.wait()
        }
    }
}

AppleDeviceManager.main()
