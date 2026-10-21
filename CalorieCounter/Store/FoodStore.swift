import Foundation
import Observation

/// Хранит записи о продуктах и сохраняет их в JSON-файл в папке Documents.
@Observable
final class FoodStore {
    private(set) var entries: [FoodEntry] = []

    private let fileURL: URL

    init(fileName: String = "food_entries.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent(fileName)
        load()
    }

    // MARK: - Запросы

    func entries(on day: Date) -> [FoodEntry] {
        entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }

    func entries(on day: Date, meal: MealType) -> [FoodEntry] {
        entries(on: day).filter { $0.meal == meal }
    }

    func totals(on day: Date) -> DailyTotals {
        DailyTotals(entries: entries(on: day))
    }

    // MARK: - Изменения

    func add(_ entry: FoodEntry) {
        entries.append(entry)
        save()
    }

    func delete(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - Сохранение

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            entries = try JSONDecoder().decode([FoodEntry].self, from: data)
        } catch {
            print("Не удалось прочитать записи: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Не удалось сохранить записи: \(error)")
        }
    }
}

extension FoodStore {
    /// Хранилище с тестовыми данными для превью.
    static var preview: FoodStore {
        let store = FoodStore(fileName: "preview_entries.json")
        if store.entries.isEmpty {
            store.add(FoodEntry(name: "Овсянка", caloriesPer100g: 88, proteinPer100g: 3, fatPer100g: 1.7, carbsPer100g: 15, grams: 250, meal: .breakfast, date: .now))
            store.add(FoodEntry(name: "Куриная грудка", caloriesPer100g: 165, proteinPer100g: 31, fatPer100g: 3.6, carbsPer100g: 0, grams: 150, meal: .lunch, date: .now))
            store.add(FoodEntry(name: "Яблоко", caloriesPer100g: 52, proteinPer100g: 0.3, fatPer100g: 0.2, carbsPer100g: 14, grams: 180, meal: .snack, date: .now))
        }
        return store
    }
}
