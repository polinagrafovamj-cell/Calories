import SwiftUI

struct DailySummaryView: View {
    @Environment(FoodStore.self) private var store
    @AppStorage("dailyCalorieGoal") private var calorieGoal = 2000

    @State private var selectedDate = Date.now
    @State private var isAddingFood = false
    @State private var isEditingGoal = false

    private var totals: DailyTotals { store.totals(on: selectedDate) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DayPicker(date: $selectedDate)
                    CaloriesRing(eaten: totals.calories, goal: Double(calorieGoal))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    MacrosRow(totals: totals)
                    MascotView(
                        hasEntries: !store.entries(on: selectedDate).isEmpty,
                        progress: calorieGoal > 0 ? totals.calories / Double(calorieGoal) : 0
                    )
                }

                ForEach(MealType.allCases) { meal in
                    let items = store.entries(on: selectedDate, meal: meal)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { entry in
                                FoodRowView(entry: entry)
                            }
                            .onDelete { offsets in
                                offsets.map { items[$0] }.forEach(store.delete)
                            }
                        } header: {
                            MealHeader(meal: meal, calories: DailyTotals(entries: items).calories)
                        }
                    }
                }

                if store.entries(on: selectedDate).isEmpty {
                    Section {
                        ContentUnavailableView {
                            VStack(spacing: 8) {
                                Image("Gopher")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100)
                                Text("Пока пусто")
                            }
                        } description: {
                            Text("Нажмите «+», чтобы добавить продукт")
                        }
                    }
                }
            }
            .navigationTitle("Калории")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Цель", systemImage: "target") { isEditingGoal = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить", systemImage: "plus") { isAddingFood = true }
                }
            }
            .sheet(isPresented: $isAddingFood) {
                AddFoodView(date: selectedDate)
            }
            .sheet(isPresented: $isEditingGoal) {
                GoalView(goal: $calorieGoal)
            }
        }
    }
}

// MARK: - Компоненты сводки

private struct DayPicker: View {
    @Binding var date: Date

    var body: some View {
        HStack {
            Button { shift(by: -1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(title)
                .font(.headline)
            Spacer()
            Button { shift(by: 1) } label: { Image(systemName: "chevron.right") }
                .disabled(Calendar.current.isDateInToday(date))
        }
        .buttonStyle(.borderless)
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Сегодня" }
        if calendar.isDateInYesterday(date) { return "Вчера" }
        return date.formatted(.dateTime.day().month(.wide).weekday(.abbreviated))
    }

    private func shift(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: date) {
            date = newDate
        }
    }
}

private struct CaloriesRing: View {
    let eaten: Double
    let goal: Double

    private var progress: Double { goal > 0 ? eaten / goal : 0 }
    private var remaining: Double { goal - eaten }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(progress > 1 ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            VStack(spacing: 4) {
                Text("\(Int(eaten.rounded()))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("из \(Int(goal)) ккал")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(remaining >= 0
                     ? "осталось \(Int(remaining.rounded()))"
                     : "превышение \(Int((-remaining).rounded()))")
                    .font(.caption)
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
            }
        }
        .frame(width: 200, height: 200)
    }
}

private struct MacrosRow: View {
    let totals: DailyTotals

    var body: some View {
        HStack {
            macro("Белки", totals.protein, .blue)
            macro("Жиры", totals.fat, .orange)
            macro("Углеводы", totals.carbs, .purple)
        }
    }

    private func macro(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f г", value))
                .font(.headline)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Суслик Санечка — талисман с репликой в зависимости от того, сколько съедено.
private struct MascotView: View {
    let hasEntries: Bool
    let progress: Double

    private var phrase: String {
        guard hasEntries else { return "Привет! Я Санечка. Что сегодня было вкусного?" }
        switch progress {
        case ..<0.5: return "Хорошее начало. Санечка одобряет!"
        case ..<0.9: return "Уже больше половины. Санечка гордится тобой!"
        case ...1: return "Норма набрана — Санечка довольна 🍊"
        default: return "Перебор! Санечка советует прогуляться."
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Image("Gopher")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64)
                Text("Санечка")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
            Text(phrase)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MealHeader: View {
    let meal: MealType
    let calories: Double

    var body: some View {
        HStack {
            Label(meal.title, systemImage: meal.icon)
            Spacer()
            Text("\(Int(calories.rounded())) ккал")
        }
    }
}

// MARK: - Цель

private struct GoalView: View {
    @Binding var goal: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Дневная норма") {
                    Stepper(value: $goal, in: 800...6000, step: 50) {
                        Text("\(goal) ккал")
                            .font(.title3.monospacedDigit())
                    }
                }
            }
            .navigationTitle("Цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DailySummaryView()
        .environment(FoodStore.preview)
}
