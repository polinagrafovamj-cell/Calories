import SwiftUI

/// Поиск продукта в базе Open Food Facts. Выбранный продукт передаётся в `onSelect`.
struct ProductSearchView: View {
    var client = OpenFoodFactsClient()
    var initialQuery = ""
    let onSelect: (FoodProduct) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var state = SearchState.idle

    private enum SearchState {
        case idle
        case loading
        case loaded([FoodProduct])
        case failed(String)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        content
            .navigationTitle("Поиск продукта")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Например, гречка или йогурт")
            .task(id: trimmedQuery) {
                await search(trimmedQuery)
            }
            .onAppear {
                if query.isEmpty { query = initialQuery }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle:
            ContentUnavailableView(
                "Найдите продукт",
                systemImage: "magnifyingglass",
                description: Text("Данные берутся из открытой базы Open Food Facts")
            )
        case .loading:
            ProgressView("Ищем…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let products) where products.isEmpty:
            ContentUnavailableView.search(text: trimmedQuery)
        case .loaded(let products):
            List(products) { product in
                Button {
                    onSelect(product)
                    dismiss()
                } label: {
                    ProductRow(product: product)
                }
                .tint(.primary)
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Не удалось загрузить", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Повторить") {
                    Task { await search(trimmedQuery, debounce: false) }
                }
            }
        }
    }

    private func search(_ text: String, debounce: Bool = true) async {
        guard text.count >= 2 else {
            state = .idle
            return
        }

        // Ждём паузу в наборе текста: при новом вводе задача отменяется.
        if debounce {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
        }

        state = .loading
        do {
            let products = try await client.search(text)
            guard !Task.isCancelled else { return }
            state = .loaded(products)
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private struct ProductRow: View {
    let product: FoodProduct

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .lineLimit(2)
                if let brand = product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(String(format: "Б %.1f · Ж %.1f · У %.1f", product.protein, product.fat, product.carbs))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(Int(product.calories.rounded()))")
                    .font(.headline.monospacedDigit())
                Text("ккал/100 г")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ProductSearchView { _ in }
    }
}
