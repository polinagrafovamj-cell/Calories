import SwiftUI
import UIKit

/// Фото, выбранное для распознавания.
struct PickedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Показывает фото и вероятные продукты на нём.
struct PhotoRecognitionView: View {
    let photo: PickedPhoto
    var recognizer = FoodRecognizer()
    let onSelect: (RecognizedFood) -> Void
    /// Открыть поиск по базе; передаётся самое вероятное название.
    let onSearch: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var state = RecognitionState.recognizing

    private enum RecognitionState {
        case recognizing
        case done([FoodGuess])
        case failed(String)
    }

    private var topGuessName: String {
        if case .done(let guesses) = state, let first = guesses.first { return first.food.name }
        return ""
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipped()
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    results
                } footer: {
                    Text("Фото обрабатывается прямо на устройстве и никуда не отправляется. Калории указаны примерно — проверьте их и вес порции.")
                }

                Section {
                    Button("Найти в базе продуктов", systemImage: "magnifyingglass") {
                        onSearch(topGuessName)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Что на фото?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .task { await recognize() }
        }
    }

    @ViewBuilder
    private var results: some View {
        switch state {
        case .recognizing:
            HStack(spacing: 12) {
                ProgressView()
                Text("Распознаём…")
                    .foregroundStyle(.secondary)
            }
        case .done(let guesses) where guesses.isEmpty:
            Text("Не удалось узнать блюдо. Попробуйте снять ближе или найдите продукт в базе.")
                .foregroundStyle(.secondary)
        case .done(let guesses):
            ForEach(guesses) { guess in
                Button {
                    onSelect(guess.food)
                    dismiss()
                } label: {
                    GuessRow(guess: guess)
                }
                .tint(.primary)
            }
        case .failed(let message):
            Text(message)
                .foregroundStyle(.secondary)
        }
    }

    private func recognize() async {
        do {
            state = .done(try await recognizer.recognize(photo.image))
        } catch {
            state = .failed("Не удалось распознать: \(error.localizedDescription)")
        }
    }
}

private struct GuessRow: View {
    let guess: FoodGuess

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(guess.food.name)
                Text("Похоже на \(Int((guess.confidence * 100).rounded()))% · порция ~\(Int(guess.food.portion)) г")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "Б %.1f · Ж %.1f · У %.1f", guess.food.protein, guess.food.fat, guess.food.carbs))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(Int(guess.food.calories.rounded()))")
                    .font(.headline.monospacedDigit())
                Text("ккал/100 г")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Съёмка фото камерой (UIImagePickerController).
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
