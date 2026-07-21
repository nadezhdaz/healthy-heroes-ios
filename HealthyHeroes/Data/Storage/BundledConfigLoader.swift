import Foundation

final class BundledConfigLoader {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func decode<Value: Decodable>(_ type: Value.Type, fileName: String) throws -> Value {
        let url = try url(for: fileName)
        let data = try Data(contentsOf: url)
        return try decoder.decode(Value.self, from: data)
    }

    private func url(for fileName: String) throws -> URL {
        let candidates = [
            bundle.url(forResource: fileName, withExtension: "json"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "Config"),
            bundle.url(forResource: fileName, withExtension: "json", subdirectory: "Resources/Config")
        ]

        if let url = candidates.compactMap({ $0 }).first {
            return url
        }

        throw ConfigLoaderError.missingFile(fileName)
    }
}

enum ConfigLoaderError: Error, Equatable {
    case missingFile(String)
}
