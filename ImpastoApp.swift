import SwiftUI

@main
struct ImpastoApp: App {
    @StateObject private var store = RecipeStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
