import SwiftUI

struct FoodRowView: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(entry.calories.rounded())) ккал")
                .font(.body.monospacedDigit())
        }
    }

    private var details: String {
        String(format: "%.0f г · Б %.1f · Ж %.1f · У %.1f",
               entry.grams, entry.protein, entry.fat, entry.carbs)
    }
}
