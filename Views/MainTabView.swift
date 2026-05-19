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
    @State private var sessionToEnd:   SessionViewModel? = nil
    @State private var sessionToLog:   SessionViewModel? = nil
    @State private var showEndOptions = false

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
                                HStack(spacing: 12) {
                                    Button("▶  Resume") {
                                        vm.isHidden = false
                                        resumedSession = vm
                                    }
                                    .buttonStyle(StesuraButtonStyle(filled: true))

                                    Button("End Session") {
                                        sessionToEnd = vm
                                        showEndOptions = true
                                    }
                                    .buttonStyle(StesuraButtonStyle(filled: false))
                                }
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
                    Button { onGoHome() } label: {
                        Image(systemName: "house")
                    }
                    .foregroundColor(.secondary)
                }
            }
            .confirmationDialog("End Session", isPresented: $showEndOptions, titleVisibility: .visible) {
                Button("End and Log") {
                    if let vm = sessionToEnd {
                        vm.stopBaking()
                        sessionToLog = vm
                    }
                    sessionToEnd = nil
                }
                Button("End without Logging", role: .destructive) {
                    if let vm = sessionToEnd { sessionManager.end(vm) }
                    sessionToEnd = nil
                }
                Button("Cancel", role: .cancel) { sessionToEnd = nil }
            } message: {
                Text("How would you like to close this session?")
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $resumedSession) { vm in
            LiveSessionView(vm: vm)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .fullScreenCover(item: $sessionToLog) { vm in
            PostBakeView(vm: vm, recipe: vm.recipe)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
    }
}
