import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: RecipeStore
    let onGoHome: () -> Void

    var body: some View {
        TabView {
            LibraryView(onGoHome: onGoHome)
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }

            Text("No active session")
                .foregroundColor(.secondary)
                .tabItem { Label("Session", systemImage: "timer") }

            HistoryView(onGoHome: onGoHome)
                .tabItem { Label("History", systemImage: "list.bullet") }
        }
        .tint(Color(hex: "D2B96A"))
    }
}
