import SwiftUI

struct TargetStepView: View {
    @Binding var ballCount: Int
    @Binding var ballWeight: Double
    @Binding var buffer: Double
    let style: PizzaStyle

    enum WeightUnit: String, CaseIterable {
        case grams  = "g"
        case ounces = "oz"
        case pounds = "lb"
    }

    @State private var unit: WeightUnit = .grams
    @State private var weightText: String = ""
    @State private var diameterText: String = ""
    @State private var bufferGramsText: String = ""

    var totalDough: Double { Double(ballCount) * ballWeight }

    var body: some View {
        List {
            Section { WizardProgressView(step: 1, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("How many balls?") {
                Stepper("\(ballCount) ball\(ballCount == 1 ? "" : "s")", value: $ballCount, in: 1...99)
                    .font(.system(.body, design: .monospaced))
            }

            Section {
                Picker("Weight unit", selection: $unit) {
                    ForEach(WeightUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                }
                .pickerStyle(.segmented)
                .onChange(of: unit) { _, _ in weightText = formattedWeight(ballWeight) }

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ball weight")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            TextField(unit == .grams ? "250" : unit == .ounces ? "8.8" : "0.55",
                                      text: $weightText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, design: .monospaced))
                                .padding(.vertical, 6).padding(.horizontal, 8)
                                .background(Color(hex: "F0EDE4"))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                                .onChange(of: weightText) { _, val in
                                    if let d = Double(val), d > 0 {
                                        ballWeight = gramsFromDisplay(d)
                                    }
                                }
                            Text(unit.rawValue)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider().frame(height: 44).padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diameter")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            TextField("—", text: $diameterText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, design: .monospaced))
                                .padding(.vertical, 6).padding(.horizontal, 8)
                                .background(Color(hex: "F0EDE4"))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                            Text("\"")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        if diameterText.isEmpty, let est = estimatedDiameter(from: ballWeight) {
                            Text("Est. \(String(format: "%.0f", est))\"")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Size per ball")
            } footer: {
                Text("Diameter is approximate · varies by stretch and thickness · leave blank to use estimate")
                    .font(.system(size: 11, design: .monospaced))
            }

            Section {
                LabeledContent("Target dough", value: formattedWeight(totalDough) + " " + unit.rawValue)
                    .font(.system(.body, design: .monospaced))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dough loss factor")
                            .font(.system(.body, design: .monospaced))
                        Text("stuck to bowl, hands, scraper")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    TextField(formattedBufferDisplay(), text: $bufferGramsText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .font(.system(.body, design: .monospaced))
                        .inputBox()
                        .onChange(of: bufferGramsText) { _, val in
                            if let d = Double(val), d >= 0, totalDough > 0 {
                                buffer = gramsFromDisplay(d) / totalDough
                            }
                        }
                    Text(unit.rawValue).foregroundColor(.secondary)
                }

                LabeledContent("Total to mix",
                               value: formattedWeight(totalDough * (1 + buffer)) + " " + unit.rawValue)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
            } footer: {
                Text("~2.5% of total dough weight is a good starting point · decreases as technique improves")
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .onAppear {
            weightText = formattedWeight(ballWeight)
            bufferGramsText = formattedBufferDisplay()
        }
        .onChange(of: unit) { _, _ in
            weightText = formattedWeight(ballWeight)
            bufferGramsText = formattedBufferDisplay()
        }
        .onChange(of: ballCount) { _, _ in
            bufferGramsText = formattedBufferDisplay()
        }
        .onChange(of: ballWeight) { _, _ in
            bufferGramsText = formattedBufferDisplay()
        }
    }

    func formattedBufferDisplay() -> String {
        let grams = buffer * totalDough
        switch unit {
        case .grams:   return String(format: "%.0f", max(0, grams))
        case .ounces:  return String(format: "%.1f", max(0, grams / 28.3495))
        case .pounds:  return String(format: "%.2f", max(0, grams / 453.592))
        }
    }

    func formattedWeight(_ grams: Double) -> String {
        switch unit {
        case .grams:   return String(format: "%.0f", grams)
        case .ounces:  return String(format: "%.1f", grams / 28.3495)
        case .pounds:  return String(format: "%.2f", grams / 453.592)
        }
    }

    func gramsFromDisplay(_ display: Double) -> Double {
        switch unit {
        case .grams:   return display
        case .ounces:  return display * 28.3495
        case .pounds:  return display * 453.592
        }
    }

    func estimatedDiameter(from grams: Double) -> Double? {
        switch style {
        case .neapolitan: return grams / 25.0
        case .newYork:    return grams / 24.0
        default:          return nil
        }
    }

}
