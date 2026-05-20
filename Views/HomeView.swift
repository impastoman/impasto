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
    @State private var showVolumeConverter = false
    @State private var pendingFormula: ConvertedFormula? = nil
    @State private var showImportRecipe = false
    @State private var showSettings = false

    private let appVersion = "0.9"

    var body: some View {
        // ZStack wrapper is always in the hierarchy — the shouldReturnHome observer
        // must live here, not on `launch`, so it remains active when MainTabView
        // is showing (showMainApp = true) and a session is re-entered from there.
        ZStack {
            if showMainApp {
                MainTabView(onGoHome: { showMainApp = false }, initialTab: initialTab)
                    .environmentObject(store)
                    .environmentObject(sessionManager)
            } else {
                launch
            }
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            guard isTrue else { return }
            showStartDough = false
            withAnimation(.easeInOut(duration: 0.35)) { showMainApp = false }
            sessionManager.shouldReturnHome = false
        }
    }

    var launch: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "F5F1E8").ignoresSafeArea()

            if splashDone {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "9A9688"))
                        .padding(12)
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
            }

            VStack(spacing: 16) {
                Spacer()

                Text("Stesura")
                    .font(.system(size: 52, design: .serif))
                    .foregroundColor(Color(hex: "2C2A24"))
                Text("Dough Manager")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "9A9688"))
                    .tracking(2)
                Text("v\(appVersion)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "C4B89A"))

                Spacer()

                if splashDone {
                    if !sessionManager.sessions.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Sessions in progress")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Color(hex: "9A9688"))
                                    .tracking(2)
                                Spacer()
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 7, height: 7)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 10)

                            ForEach(sessionManager.sessions) { vm in
                                Divider().padding(.horizontal, 16)
                                ActiveSessionRow(vm: vm)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }

                            Divider().padding(.horizontal, 16)

                            Button("▶  Check Sessions") {
                                initialTab = 1
                                showMainApp = true
                            }
                            .buttonStyle(StesuraButtonStyle(filled: true))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        .cornerRadius(8)
                    }

                }

                if splashDone {
                Divider().background(Color(hex: "D8D4C8"))

                Button("Start Dough →") { showStartDough = true }
                    .buttonStyle(StesuraButtonStyle(filled: true))

                Button("+ New Recipe") { showNewMenu = true }
                    .buttonStyle(StesuraButtonStyle(filled: false))
                    .confirmationDialog("Create New", isPresented: $showNewMenu, titleVisibility: .visible) {
                        Button("New Recipe") { showWizard = true }
                        Button("Convert a Volume Recipe") { showVolumeConverter = true }
                        Button("New Flour Blend") { showBlendBuilder = true }
                        Button("New Process") { showProcessBuilder = true }
                        Button("New Preferment") { showPrefBuilder = true }
                        Button("Cancel", role: .cancel) {}
                    }

                Button("Library") { showMainApp = true }
                    .buttonStyle(StesuraButtonStyle(filled: false))

                Button("↑  Import Recipe") { showImportRecipe = true }
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
        .sheet(isPresented: $showVolumeConverter) {
            VolumeConverterView { formula in
                pendingFormula = formula
                showVolumeConverter = false
            }
        }
        .sheet(item: $pendingFormula) { formula in
            WizardContainerView(convertedFormula: formula) { recipe in
                store.add(recipe)
                store.activeRecipeId = recipe.id
                pendingFormula = nil
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
        .sheet(isPresented: $showImportRecipe) {
            ImportRecipeView().environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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

// MARK: - Active session row (observes its own VM for live timer updates)

private struct ActiveSessionRow: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.recipe.name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "2C2A24"))
                    .lineLimit(1)
                Text(stepLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(vm.isInBakeStep ? timeString(vm.bakeElapsed) : timeString(vm.elapsed))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(vm.isOvertime ? .orange : Color(hex: "D2B96A"))
                if vm.isOvertime {
                    Text("overtime")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }

            Circle()
                .fill(vm.isRunning ? Color(hex: "6DBF8A") : Color.orange)
                .frame(width: 7, height: 7)
        }
    }

    private var stepLabel: String {
        if vm.isInBakeStep { return "BAKE" }
        return vm.currentCard?.title.uppercased() ?? ""
    }

    private func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: -

struct StartDoughView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showWizard = false
    @State private var selectedRecipe: Recipe? = nil
    @State private var preFlightRecipe: Recipe? = nil

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
                        Button("Begin Prep →") { preFlightRecipe = selectedRecipe }
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.system(size: 13, design: .monospaced))
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $preFlightRecipe) { r in
            PreFlightView(recipe: r)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                showWizard = false
            }
        }
    }
}
