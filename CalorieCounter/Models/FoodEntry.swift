import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: "Завтрак"
        case .lunch: "Обед"
        case .dinner: "Ужин"
        case .snack: "Перекус"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "carrot.fill"
        }
    }
}

struct FoodEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    /// Калорийность на 100 г
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double
    /// Вес порции в граммах
    var grams: Double
    var meal: MealType
    var date: Date

    private var factor: Double { grams / 100 }

    var calories: Double { caloriesPer100g * factor }
    var protein: Double { proteinPer100g * factor }
    var fat: Double { fatPer100g * factor }
    var carbs: Double { carbsPer100g * factor }
}

struct DailyTotals {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    init(entries: [FoodEntry] = []) {
        for entry in entries {
            calories += entry.calories
            protein += entry.protein
            fat += entry.fat
            carbs += entry.carbs
        }
    }
}
