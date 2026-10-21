import SwiftUI

@main
struct CalorieCounterApp: App {
    @State private var store = FoodStore()

    var body: some Scene {
        WindowGroup {
            DailySummaryView()
                .environment(store)
        }
    }
}
