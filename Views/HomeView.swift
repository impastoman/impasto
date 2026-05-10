import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showWizard = false
    @State private var showMainApp = false

    var body: some View {
        if showMainApp {
            MainTabView().environmentObject(store)
        } else {
            launch
        }
    }

    var launch: some View {
        ZStack {
            Color(hex: "111210").ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Impasto")
                    .font(.system(size: 52, design: .serif))
                    .foregroundColor(Color(hex: "D2B96A"))
                Text("Pizza Dough Manager")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "9A9688"))
                    .tracking(2)

                Spacer()

                if let active = store.activeRecipe {
                    VStack(spacing: 10) {
                        Text("last session")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(hex: "4A4840"))
                            .tracking(2)
                        Text(active.name)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(Color(hex: "E8E4D8"))
                        Button("▶  Continue") { showMainApp = true }
                            .buttonStyle(ImpastoButtonStyle(filled: true))
                    }
                    .padding(16)
                    .background(Color(hex: "1A1B18"))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D2B96A").opacity(0.3), lineWidth: 1))
                    .cornerRadius(8)
                }

                Divider().background(Color(hex: "2A2A28"))

                Button("+ New Recipe") { showWizard = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("Library") { showMainApp = true }
                    .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("↑  Import Recipe") {}
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "3A3830"))

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
    }
}
