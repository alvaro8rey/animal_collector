import Foundation

struct AnimalData {
    static let all: [Animal] = {
        guard let url = Bundle.main.url(forResource: "animals", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            assertionFailure("animals.json not found in bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Animal].self, from: data)
        } catch {
            assertionFailure("Failed to decode animals.json: \(error)")
            return []
        }
    }()
}
