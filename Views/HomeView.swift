import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showWizard = false
    @State private var showMainApp = false
    @State private var showStartDough = false

    private let appVersion = "0.4"

    var body: some View {
        if showMainApp {
            MainTabView().environmentObject(store)
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

                if let active = store.activeRecipe {
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

                Divider().background(Color(hex: "D8D4C8"))

                Button("Start Dough →") { showStartDough = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))

                Button("+ New Recipe") { showWizard = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("Library") { showMainApp = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("↑  Import Recipe") {}
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "C4B89A"))

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                store.activeRecipeId = recipe.id
                showWizard = false
                showMainApp = true
            }
        }
        .sheet(isPresented: $showStartDough) {
            StartDoughView()
                .environmentObject(store)
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
                        NavigationLink("Pre-Flight →") {
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
