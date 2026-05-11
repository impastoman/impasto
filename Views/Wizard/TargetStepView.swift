import SwiftUI

struct TargetStepView: View {
    @Binding var ballCount: Int
    @Binding var ballWeight: Double
    @Binding var buffer: Double

    let presets: [(Double, String)] = [(250, "10\""), (280, "11\""), (340, "12\"")]

    var body: some View {
        List {
            Section { WizardProgressView(step: 1, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("How many balls?") {
                Stepper("\(ballCount) balls", value: $ballCount, in: 1...99)
            }

            Section("Size per ball") {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.0) { weight, size in
                        VStack(spacing: 3) {
                            Text("\(Int(weight))g")
                                .font(.system(size: 16, design: .monospaced))
                                .fontWeight(ballWeight == weight ? .semibold : .regular)
                            Text(size).font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ballWeight == weight ? Color(hex: "D2B96A").opacity(0.14) : Color(hex: "1C1C1E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ballWeight == weight ? Color(hex: "D2B96A") : Color.clear, lineWidth: 1)
                        )
                        .cornerRadius(8)
                        .onTapGesture { ballWeight = weight }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                LabeledContent("Target dough", value: "\(Int(Double(ballCount) * ballWeight))g")
                    .font(.system(.body, design: .monospaced))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Buffer")
                            .font(.system(.body, design: .monospaced))
                        Text("dough loss factor")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    TextField("2", value: Binding(
                        get: { Int(buffer * 100) },
                        set: { buffer = Double($0) / 100 }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 44)
                    .font(.system(.body, design: .monospaced))
                    Text("%").foregroundColor(.secondary)
                }

                LabeledContent("Total with buffer", value: "\(Int(Double(ballCount) * ballWeight * (1 + buffer)))g")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
            }
        }
    }
}
