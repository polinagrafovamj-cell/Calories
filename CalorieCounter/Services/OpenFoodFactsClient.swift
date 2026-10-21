import Foundation

/// Продукт из базы Open Food Facts с пищевой ценностью на 100 г.
struct FoodProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
}

/// Клиент для поиска продуктов в открытой базе Open Food Facts.
/// Документация: https://openfoodfacts.github.io/openfoodfacts-server/api/
struct OpenFoodFactsClient {
    enum ClientError: LocalizedError {
        case badResponse(Int)

        var errorDescription: String? {
            switch self {
            case .badResponse(let code): "Сервер ответил с кодом \(code)"
            }
        }
    }

    var session: URLSession = .shared

    func search(_ query: String, pageSize: Int = 30) async throws -> [FoodProduct] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "lc", value: "ru"),
            URLQueryItem(name: "sort_by", value: "unique_scans_n"),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "fields", value: "code,product_name,product_name_ru,brands,nutriments"),
        ]

        var request = URLRequest(url: components.url!)
        // Open Food Facts просит указывать User-Agent с названием приложения.
        request.setValue("CalorieCounter/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badResponse(http.statusCode)
        }

        let result = try JSONDecoder().decode(SearchResponse.self, from: data)
        var seen = Set<String>()
        return result.products
            .compactMap(FoodProduct.init)
            .filter { seen.insert($0.id).inserted }
    }
}

// MARK: - Формат ответа API

private struct SearchResponse: Decodable {
    let products: [Product]

    struct Product: Decodable {
        let code: String?
        let product_name: String?
        let product_name_ru: String?
        let brands: String?
        let nutriments: Nutriments?
    }

    struct Nutriments: Decodable {
        let energyKcal: FlexibleDouble?
        let energyKJ: FlexibleDouble?
        let proteins: FlexibleDouble?
        let fat: FlexibleDouble?
        let carbohydrates: FlexibleDouble?

        enum CodingKeys: String, CodingKey {
            case energyKcal = "energy-kcal_100g"
            case energyKJ = "energy_100g"
            case proteins = "proteins_100g"
            case fat = "fat_100g"
            case carbohydrates = "carbohydrates_100g"
        }
    }
}

/// В базе числа иногда приходят строками, поэтому принимаем оба варианта.
private struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            value = number
        } else if let number = Double(try container.decode(String.self).replacingOccurrences(of: ",", with: ".")) {
            value = number
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Не число")
        }
    }
}

private extension FoodProduct {
    init?(_ product: SearchResponse.Product) {
        let name = [product.product_name_ru, product.product_name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        guard let name, let code = product.code, let nutriments = product.nutriments else { return nil }

        // Если калорий нет, пересчитываем из килоджоулей.
        guard let calories = nutriments.energyKcal?.value ?? nutriments.energyKJ.map({ $0.value / 4.184 }) else {
            return nil
        }

        let brand = product.brands?
            .split(separator: ",")
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) }

        self.init(
            id: code,
            name: name,
            brand: brand?.isEmpty == false ? brand : nil,
            calories: calories,
            protein: nutriments.proteins?.value ?? 0,
            fat: nutriments.fat?.value ?? 0,
            carbs: nutriments.carbohydrates?.value ?? 0
        )
    }
}
