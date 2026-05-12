import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    let onGoHome: () -> Void
    @State private var selectedTab: Int

    init(onGoHome: @escaping () -> Void, initialTab: Int = 0) {
        self.onGoHome = onGoHome
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(onGoHome: onGoHome)
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }
                .tag(0)

            ActiveSessionsView(onGoHome: onGoHome)
                .tabItem { Label("Sessions", systemImage: "timer") }
                .tag(1)

            HistoryView(onGoHome: onGoHome)
                .tabItem { Label("History", systemImage: "list.bullet") }
                .tag(2)
        }
        .tint(Color(hex: "D2B96A"))
    }
}

struct ActiveSessionsView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    let onGoHome: () -> Void
    @State private var resumedSession: SessionViewModel? = nil

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.sessions.isEmpty {
                    ContentUnavailableView(
                        "No active sessions",
                        systemImage: "timer",
                        description: Text("Start a dough session from the home screen or library.")
                    )
                } else {
                    List {
                        ForEach(sessionManager.sessions) { vm in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(vm.recipe.name)
                                            .font(.system(size: 15, design: .monospaced))
                                            .foregroundColor(.primary)
                                        Text("Step \(vm.currentIndex + 1) of \(vm.cards.count)  ·  \(vm.recipe.method.rawValue)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                }
                                Button("▶  Resume") {
                                    vm.isHidden = false
                                    resumedSession = vm
                                }
                                .buttonStyle(ImpastoButtonStyle(filled: true))
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("⌂ Home") { onGoHome() }
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $resumedSession) { vm in
            LiveSessionView(vm: vm)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
    }
}
