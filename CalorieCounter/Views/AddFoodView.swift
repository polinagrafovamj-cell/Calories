import SwiftUI

struct AddFoodView: View {
    let date: Date

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var meal = MealType.suggested()
    @State private var grams = "100"
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""

    @FocusState private var focusedField: Field?

    private enum Field { case name, grams, calories, protein, fat, carbs }

    private var draft: FoodEntry? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty,
              let grams = Self.number(grams), grams > 0,
              let calories = Self.number(calories), calories >= 0
        else { return nil }

        return FoodEntry(
            name: trimmedName,
            caloriesPer100g: calories,
            proteinPer100g: Self.number(protein) ?? 0,
            fatPer100g: Self.number(fat) ?? 0,
            carbsPer100g: Self.number(carbs) ?? 0,
            grams: grams,
            meal: meal,
            date: date
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ProductSearchView { product in
                            apply(name: product.name, calories: product.calories,
                                  protein: product.protein, fat: product.fat, carbs: product.carbs)
                        }
                    } label: {
                        Label("Найти в базе продуктов", systemImage: "magnifyingglass")
                    }
                } footer: {
                    Text("Поиск по открытой базе Open Food Facts")
                }

                Section("Продукт") {
                    TextField("Название", text: $name)
                        .focused($focusedField, equals: .name)
                    Picker("Приём пищи", selection: $meal) {
                        ForEach(MealType.allCases) { meal in
                            Label(meal.title, systemImage: meal.icon).tag(meal)
                        }
                    }
                    numberField("Вес порции", text: $grams, unit: "г", field: .grams)
                }

                Section("На 100 г") {
                    numberField("Калории", text: $calories, unit: "ккал", field: .calories)
                    numberField("Белки", text: $protein, unit: "г", field: .protein)
                    numberField("Жиры", text: $fat, unit: "г", field: .fat)
                    numberField("Углеводы", text: $carbs, unit: "г", field: .carbs)
                }

                Section("Быстрый выбор") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(FoodPreset.all) { preset in
                                Button(preset.name) {
                                    apply(name: preset.name, calories: preset.calories,
                                          protein: preset.protein, fat: preset.fat, carbs: preset.carbs)
                                }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                if let draft {
                    Section("Итого за порцию") {
                        FoodRowView(entry: draft)
                    }
                }
            }
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        if let draft {
                            store.add(draft)
                            dismiss()
                        }
                    }
                    .disabled(draft == nil)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") { focusedField = nil }
                }
            }
            .onAppear { if name.isEmpty { focusedField = .name } }
        }
    }

    private func numberField(_ title: String, text: Binding<String>, unit: String, field: Field) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .focused($focusedField, equals: field)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private func apply(name: String, calories: Double, protein: Double, fat: Double, carbs: Double) {
        self.name = name
        self.calories = Self.format(calories)
        self.protein = Self.format(protein)
        self.fat = Self.format(fat)
        self.carbs = Self.format(carbs)
    }

    /// Разбирает число, принимая и точку, и запятую как разделитель.
    private static func number(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private extension MealType {
    /// Предлагает приём пищи по текущему времени суток.
    static func suggested(for date: Date = .now) -> MealType {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 16..<22: .dinner
        default: .snack
        }
    }
}

// MARK: - Пресеты

private struct FoodPreset: Identifiable {
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double

    var id: String { name }

    static let all: [FoodPreset] = [
        FoodPreset(name: "Гречка", calories: 110, protein: 4.2, fat: 1.1, carbs: 21.3),
        FoodPreset(name: "Рис", calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
        FoodPreset(name: "Куриная грудка", calories: 165, protein: 31, fat: 3.6, carbs: 0),
        FoodPreset(name: "Яйцо", calories: 155, protein: 13, fat: 11, carbs: 1.1),
        FoodPreset(name: "Творог 5%", calories: 121, protein: 17, fat: 5, carbs: 1.8),
        FoodPreset(name: "Банан", calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
        FoodPreset(name: "Яблоко", calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
        FoodPreset(name: "Хлеб", calories: 265, protein: 9, fat: 3.2, carbs: 49),
    ]
}

#Preview {
    AddFoodView(date: .now)
        .environment(FoodStore.preview)
}
