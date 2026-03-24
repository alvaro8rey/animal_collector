import Foundation

struct AnimalData {

    private static let remoteURL = URL(string: "https://pub-7042a31e227d46569e518a96fcc9951a.r2.dev/animals.json")!

    private static let cacheURL: URL =
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("animals_remote.json")

    /// Synchronous load used at startup: disk cache → bundle fallback.
    static var initial: [Animal] {
        if let animals = load(from: cacheURL) { return animals }
        return bundle
    }

    /// Fetches the remote JSON in the background, updates the disk cache,
    /// and calls `completion` on the main thread only if the animal list changed.
    /// `onComplete` is always called on the main thread when the request finishes;
    /// its Bool argument is `true` if a network or parse error occurred.
    static func fetchRemote(
        current: [Animal],
        completion: @escaping ([Animal]) -> Void,
        onComplete: ((Bool) -> Void)? = nil
    ) {
        URLSession.shared.dataTask(with: remoteURL) { data, response, _ in
            var updated: [Animal]? = nil
            var failed = false
            if let data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               let animals = try? JSONDecoder().decode([Animal].self, from: data) {
                try? data.write(to: cacheURL, options: .atomic)
                if animals.map(\.id) != current.map(\.id) {
                    updated = animals
                }
            } else {
                failed = true
            }
            DispatchQueue.main.async {
                if let updated { completion(updated) }
                onComplete?(failed)
            }
        }.resume()
    }

    // MARK: - Private helpers

    private static var bundle: [Animal] {
        guard
            let url = Bundle.main.url(forResource: "animals", withExtension: "json"),
            let animals = load(from: url)
        else { return [] }
        return animals
    }

    private static func load(from url: URL) -> [Animal]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([Animal].self, from: data)
    }
}
