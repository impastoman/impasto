import SwiftUI

/// Wizard step 0 — name the recipe and its style. The app is
/// dough-agnostic: rather than pick from prebuilt pizza styles, the
/// baker names their own style ("Country loaf", "Focaccia", "NY pizza",
/// whatever). The recipe always saves with style == .custom and these
/// free-text values; balanced defaults flow from PizzaStyle.custom and
/// are tuned in the following steps.
struct StyleStepView: View {
    @Binding var name: String
    @Binding var customStyleName: String

    var body: some View {
        List {
            Section { WizardProgressView(step: 0, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section(header: Text("Name your dough").font(.jakarta(.semibold, size: 13))) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recipe name")
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.secondary)
                    TextField("e.g. Saturday Sourdough", text: $name)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Style")
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.secondary)
                    TextField("e.g. Country loaf, Focaccia, NY pizza", text: $customStyleName)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
        }
        .meadList()
    }
}
