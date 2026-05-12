import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showNewMenu = false
    @State private var showWizard = false
    @State private var showBlendBuilder = false
    @State private var showProcessBuilder = false
    @State private var showPrefBuilder = false
    @State private var showMainApp = false
    @State private var showStartDough = false
    @State private var splashDone = false
    @State private var resumedSession: SessionViewModel? = nil
    @State private var initialTab: Int = 0

    private let appVersion = "0.8"

    var body: some View {
        if showMainApp {
            MainTabView(onGoHome: { showMainApp = false }, initialTab: initialTab)
                .environmentObject(store)
                .environmentObject(sessionManager)
        } else {
            launch
        }
    }

    var launch: some View {
        ZStack {
            Color(hex: "F5F1E8").ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Impasto")
                    .font(.system(size: 52, design: .serif))
                    .foregroundColor(Color(hex: "2C2A24"))
                Text("Pizza Dough Manager")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "9A9688"))
                    .tracking(2)
                Text("v\(appVersion)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "C4B89A"))

                Spacer()

                if splashDone {
                    if !sessionManager.sessions.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Sessions in progress")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Color(hex: "9A9688"))
                                        .tracking(2)
                                    Text("\(sessionManager.sessions.count) active")
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(Color(hex: "2C2A24"))
                                }
                                Spacer()
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                            }
                            Button("▶  Check Sessions") {
                                initialTab = 1
                                showMainApp = true
                            }
                            .buttonStyle(ImpastoButtonStyle(filled: true))
                        }
                        .padding(16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        .cornerRadius(8)
                    }

                    if let active = store.activeRecipe, sessionManager.sessions.isEmpty {
                        VStack(spacing: 10) {
                            Text("last session")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(hex: "9A9688"))
                                .tracking(2)
                            Text(active.name)
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(Color(hex: "2C2A24"))
                            Button("▶  Continue") { showMainApp = true }
                                .buttonStyle(ImpastoButtonStyle(filled: true))
                        }
                        .padding(16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                        .cornerRadius(8)
                    }
                }

                if splashDone {
                Divider().background(Color(hex: "D8D4C8"))

                Button("Start Dough →") { showStartDough = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))

                Button("+ New Recipe") { showNewMenu = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))
                    .confirmationDialog("Create New", isPresented: $showNewMenu, titleVisibility: .visible) {
                        Button("New Recipe") { showWizard = true }
                        Button("New Flour Blend") { showBlendBuilder = true }
                        Button("New Process") { showProcessBuilder = true }
                        Button("New Preferment") { showPrefBuilder = true }
                        Button("Cancel", role: .cancel) {}
                    }

                Button("Library") { showMainApp = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("↑  Import Recipe") {}
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "C4B89A"))
                } // end splashDone

                Spacer()
            }
            .padding(.horizontal, 32)
            .onAppear {
                guard !splashDone else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeIn(duration: 0.4)) { splashDone = true }
                }
            }
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                store.activeRecipeId = recipe.id
                showWizard = false
                showMainApp = true
            }
        }
        .sheet(isPresented: $showBlendBuilder) {
            StandaloneBlendBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showProcessBuilder) {
            StandaloneProcessBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showPrefBuilder) {
            StandalonePrefermentBuilderView().environmentObject(store)
        }
        .sheet(isPresented: $showStartDough) {
            StartDoughView()
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .fullScreenCover(item: $resumedSession) { vm in
            LiveSessionView(vm: vm)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
    }
}

struct StartDoughView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showWizard = false
    @State private var selectedRecipe: Recipe? = nil

    var body: some View {
        NavigationStack {
            List {
                if !store.recipes.isEmpty {
                    Section("Choose a recipe") {
                        ForEach(store.recipes) { recipe in
                            Button {
                                selectedRecipe = recipe
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(recipe.name).font(.headline).foregroundColor(.primary)
                                        Text("\(recipe.style.rawValue)  ·  \(recipe.method.rawValue)  ·  \(recipe.ballCount) balls")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedRecipe?.id == recipe.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "D2B96A"))
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Build one now →") { showWizard = true }
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
            .navigationTitle("Start Dough")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if selectedRecipe != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink("Begin Prep →") {
                            if let r = selectedRecipe {
                                PreFlightView(recipe: r).environmentObject(store)
                            }
                        }
                        .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            }
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                showWizard = false
            }
        }
    }
}
