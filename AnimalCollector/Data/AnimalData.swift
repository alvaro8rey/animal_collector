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
    static func fetchRemote(current: [Animal], completion: @escaping ([Animal]) -> Void) {
        URLSession.shared.dataTask(with: remoteURL) { data, response, _ in
            guard
                let data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let animals = try? JSONDecoder().decode([Animal].self, from: data)
            else { return }

            try? data.write(to: cacheURL, options: .atomic)

            guard animals.map(\.id) != current.map(\.id) else { return }
            DispatchQueue.main.async { completion(animals) }
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
