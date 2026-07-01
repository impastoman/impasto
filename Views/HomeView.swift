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
    @State private var stagedFormula: ConvertedFormula? = nil
    @State private var showImportRecipe = false
    @State private var showSettings = false

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
        ZStack {
            Color(hex: "FAFAF5").ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Stesura")
                    .font(.fraunces(.semibold, size: 56))
                    .foregroundColor(Color(hex: "2C2A24"))
                Text("Dough Notebook")
                    .font(.jakarta(.medium, size: 11))
                    .foregroundColor(Color(hex: "9A9688"))
                    .tracking(2)
                Spacer()

                if splashDone {
                    if !sessionManager.sessions.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Sessions in progress")
                                    .font(.jakarta(.regular, size: 9))
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
                        Button("New Recipe") {
                            if store.canAddRecipe { showWizard = true } else { store.requestPaywall() }
                        }
                        Button("Convert a Volume Recipe") {
                            if store.canAddRecipe { showVolumeConverter = true } else { store.requestPaywall() }
                        }
                        Button("New Flour Blend") {
                            if store.canAddBlend { showBlendBuilder = true } else { store.requestPaywall() }
                        }
                        Button("New Process") {
                            if store.canAddProcess { showProcessBuilder = true } else { store.requestPaywall() }
                        }
                        Button("New Preferment") {
                            if store.canAddPreferment { showPrefBuilder = true } else { store.requestPaywall() }
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                Button("Library") { showMainApp = true }
                    .buttonStyle(StesuraButtonStyle(filled: false))

                Button("↑  Import Recipe") { showImportRecipe = true }
                    .font(.jakarta(.regular, size: 11))
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
        .overlay(alignment: .topTrailing) {
            if splashDone {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "9A9688"))
                        .padding(12)
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showWizard, onDismiss: { pendingFormula = nil }) {
            // One wizard sheet for both "+ New Recipe" (pendingFormula nil) and the
            // volume-converter handoff (pendingFormula set). Reusing the proven
            // sheet avoids a second wizard sheet that presented blank.
            WizardContainerView(convertedFormula: pendingFormula) { recipe in
                store.add(recipe)
                store.activeRecipeId = recipe.id
                showWizard = false
                showMainApp = true
            }
        }
        .sheet(isPresented: $showVolumeConverter, onDismiss: {
            // Open the wizard only after the converter sheet has fully torn down —
            // presenting a second sheet from the same view mid-dismiss gives a
            // blank sheet. The delay clears the dismiss animation first.
            if let f = stagedFormula {
                stagedFormula = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    pendingFormula = f
                    showWizard = true
                }
            }
        }) {
            VolumeConverterView { formula in
                stagedFormula = formula
                showVolumeConverter = false
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
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(Color(hex: "2C2A24"))
                    .lineLimit(1)
                Text(stepLabel)
                    .font(.jakarta(.regular, size: 9))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(previewTime)
                    .font(.jakarta(.regular, size: 14))
                    .foregroundColor(vm.isOvertime ? .orange : Color(hex: "7FA2BD"))
                if vm.isOvertime {
                    Text("overtime")
                        .font(.jakarta(.regular, size: 9))
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

    /// Minimized session preview:
    ///   • Bake step → count UP (no target duration)
    ///   • Current step has a duration → count DOWN to 0; flip to +MM:SS overtime
    ///   • Current step is action-only (duration == 0) → count UP
    /// Mode-agnostic — works the same in Automatic and Manual.
    private var previewTime: String {
        if vm.isInBakeStep { return timeString(vm.bakeElapsed) }
        let target = vm.currentCard?.duration ?? 0
        if target > 0 {
            let remaining = target - vm.elapsed
            if remaining >= 0 {
                return countdown(remaining)
            } else {
                return "+" + countdown(-remaining)
            }
        }
        return timeString(vm.elapsed)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Compact MM:SS (or HH:MM:SS when ≥ 1 hour). Used by the countdown branch
    /// where the user cares about remaining minutes, not the H placeholder.
    private func countdown(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        let h = total / 3600; let m = (total % 3600) / 60; let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
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
                    Section(header: Text("Choose a recipe").font(.jakarta(.semibold, size: 13))) {
                        ForEach(store.recipes) { recipe in
                            Button {
                                selectedRecipe = recipe
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(recipe.name).font(.jakarta(.semibold, size: 17)).foregroundColor(.primary)
                                        Text("\(recipe.style.rawValue)  ·  \(recipe.method.rawValue)  ·  \(recipe.ballCount) balls")
                                            .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedRecipe?.id == recipe.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "7FA2BD"))
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Build one now →") { showWizard = true }
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
            }
            .meadList()
            .navigationTitle("Start Dough")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if selectedRecipe != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Begin Prep →") { preFlightRecipe = selectedRecipe }
                            .foregroundColor(Color(hex: "7FA2BD"))
                            .font(.jakarta(.regular, size: 13))
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
