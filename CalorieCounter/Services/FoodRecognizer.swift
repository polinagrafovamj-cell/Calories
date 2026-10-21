import ImageIO
import UIKit
import Vision

/// Продукт, который умеет распознавать приложение. КБЖУ — на 100 г, `portion` — типичная порция в граммах.
struct RecognizedFood: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let portion: Double
    /// Идентификаторы классов Apple Vision, которые означают этот продукт.
    let vision: [String]
}

struct FoodGuess: Identifiable, Hashable {
    let food: RecognizedFood
    let confidence: Float

    var id: String { food.id }
}

/// Распознаёт еду на фото встроенным в iOS классификатором Vision —
/// прямо на устройстве, без интернета и без отправки фото куда-либо.
struct FoodRecognizer {
    enum RecognizerError: LocalizedError {
        case badImage

        var errorDescription: String? { "Не удалось прочитать изображение" }
    }

    private static let minimumConfidence: Float = 0.1

    /// Таблица продуктов, общая с веб-версией (web/recognized-foods.json).
    static let foods: [RecognizedFood] = {
        struct Table: Decodable { let foods: [RecognizedFood] }

        guard let url = Bundle.main.url(forResource: "recognized-foods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(Table.self, from: data)
        else {
            print("Не удалось загрузить recognized-foods.json")
            return []
        }
        return table.foods
    }()

    private static let foodsByIdentifier: [String: RecognizedFood] = {
        var result: [String: RecognizedFood] = [:]
        for food in foods {
            for identifier in food.vision { result[identifier] = food }
        }
        return result
    }()

    /// Возвращает до трёх вероятных продуктов; пустой массив — ничего знакомого на фото нет.
    func recognize(_ image: UIImage) async throws -> [FoodGuess] {
        guard let cgImage = image.cgImage else { throw RecognizerError.badImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await Task.detached(priority: .userInitiated) {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            try handler.perform([request])

            // Vision выдаёт сотни меток («food», «plate», «pizza»…); оставляем только известные продукты.
            var best: [String: FoodGuess] = [:]
            for observation in request.results ?? [] where observation.confidence >= Self.minimumConfidence {
                guard let food = Self.foodsByIdentifier[observation.identifier.lowercased()] else { continue }
                if observation.confidence > best[food.id]?.confidence ?? 0 {
                    best[food.id] = FoodGuess(food: food, confidence: observation.confidence)
                }
            }
            return Array(best.values.sorted { $0.confidence > $1.confidence }.prefix(3))
        }.value
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
