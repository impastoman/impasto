import SwiftUI

struct StyleStepView: View {
    @Binding var selected: PizzaStyle

    var body: some View {
        List {
            Section { WizardProgressView(step: 0, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("What style?") {
                ForEach(PizzaStyle.allCases, id: \.self) { style in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(style.rawValue).font(.headline)
                            Text(style.description).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if selected == style {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = style }
                }
            }
        }
    }
}
