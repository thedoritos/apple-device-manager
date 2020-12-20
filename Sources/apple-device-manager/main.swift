import Foundation
import ArgumentParser

struct AppleDeviceManager: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "adm",
        abstract: "Apple Device Manager",
        subcommands: [List.self, Disable.self]
    )
}

extension AppleDeviceManager {
    struct Options: ParsableArguments {
        @Option(help: "Path to the private key.", completion: .file(extensions: [".p8"]))
        var keyPath: String?

        @Option(help: "Content of the private key.", completion: .file(extensions: [".p8"]))
        var keyValue: String?

        @Option(help: "Id of the private key.")
        var keyId: String

        @Option(help: "Id of the issuer of private key.")
        var issuerId: String

        func validate() throws {
            if keyPath == nil && keyValue == nil {
                throw ValidationError("Either '--key-path' or '--key-value' must be given.")
            }
        }

        func getKey() throws -> APIKey {
            if let keyValue = self.keyValue {
                return APIKey(id: keyId, issuerId: issuerId, value: keyValue.replacingOccurrences(of: "\\n", with: "\n"))
            }

            let keyValue = try String(contentsOfFile: keyPath!)
            return APIKey(id: keyId, issuerId: issuerId, value: keyValue)
        }
    }

    struct List: ParsableCommand {
        @OptionGroup var baseOptions: Options

        mutating func run() throws {
            let key = try baseOptions.getKey()
            let token = try APIToken.encode(key)

            let result = Session.send(GetDeivcesRequest(token: token))
            switch result {
                case .success(let response):
                    DevicePrinter().print(response.data)
                case .failure(let error):
                    AppleDeviceManager.exit(withError: error)
            }
        }
    }

    struct Disable: ParsableCommand {
        @OptionGroup var baseOptions: Options

        @Option(help: "Years elapsed after registration.")
        var age: Int

        mutating func run() throws {
            let key = try baseOptions.getKey()
            let token = try APIToken.encode(key)

            var devices: [Device] = []

            let result = Session.send(GetDeivcesRequest(token: token))
            switch result {
                case .success(let response):
                    devices = response.data
                case .failure(let error):
                    AppleDeviceManager.exit(withError: error)
            }

            devices.forEach { device in
                let years = Calendar.current.dateComponents([.year], from: device.attributes.addedDate, to: Date()).year ?? 0

                if years < age { return }
                if case .disabled = device.attributes.status { return }

                let body = DeviceUpdateRequest(data: .init(attributes: .init(status: .disabled), id: device.id))
                let result = Session.send(PatchDevicesRequest(token: token, body: body))
                switch result {
                    case .success(let response):
                        DevicePrinter().print(response.data)
                    case .failure(let error):
                        AppleDeviceManager.exit(withError: error)
                }
            }
        }
    }
}

AppleDeviceManager.main()
