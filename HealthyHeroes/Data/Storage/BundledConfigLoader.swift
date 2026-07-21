import Foundation

final class BundledConfigLoader {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let lock = NSLock()
    private var cachedValues: [String: Any] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func decode<Value: Decodable>(_ type: Value.Type, fileName: String) throws -> Value {
        let cacheKey = "\(fileName):\(String(reflecting: Value.self))"
        lock.lock()
        defer { lock.unlock() }

        if let cachedValue = cachedValues[cacheKey] as? Value {
            return cachedValue
        }

        let url = try url(for: fileName)
        let data = try Data(contentsOf: url)
        let value = try decoder.decode(Value.self, from: data)
        cachedValues[cacheKey] = value
        return value
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
