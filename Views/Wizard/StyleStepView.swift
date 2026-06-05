import SwiftUI

struct StyleStepView: View {
    @Binding var selected: PizzaStyle
    @Binding var customStyleName: String

    var body: some View {
        List {
            Section { WizardProgressView(step: 0, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section(header: Text("What style?").font(.jakarta(.semibold, size: 13))) {
                ForEach(PizzaStyle.allCases, id: \.self) { style in
                    if style == .custom {
                        customRow
                    } else {
                        styleRow(style)
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
    }

    func styleRow(_ style: PizzaStyle) -> some View {
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

    var customRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("My Style").font(.headline)
                    Text("Your rules · your ratios").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if selected == .custom {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { selected = .custom }

            if selected == .custom {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("My Style", text: $customStyleName)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()

                    Text("No style presets — balanced defaults are applied. Adjust hydration, ratios, and process after saving.")
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                        .tipText()
                }
            }
        }
        .padding(.vertical, 2)
    }
}
