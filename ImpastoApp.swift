import SwiftUI

@main
struct ImpastoApp: App {
    @StateObject private var store = RecipeStore()
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(sessionManager)
                .preferredColorScheme(.light)
        }
    }
}
