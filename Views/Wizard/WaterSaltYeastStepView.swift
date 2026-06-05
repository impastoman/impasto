import SwiftUI

struct WaterSaltYeastStepView: View {
    @Binding var finalHydration: Double
    @Binding var saltPct: Double
    @Binding var yeastPct: Double
    @Binding var yeastType: YeastType
    let styleDefault: Double
    var isFromConversion: Bool = false

    @State private var hydrationText: String = ""
    @State private var saltText: String = ""
    @State private var yeastText: String = ""
    @State private var hydrateOwnWay: Bool = false

    var body: some View {
        List {
            Section { WizardProgressView(step: 4, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section {
                Toggle(isOn: $hydrateOwnWay) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hydrate your own way")
                            .font(.jakarta(.regular, size: 17))
                        Text("Enter any value from 1â€“999%")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.secondary)
                            .tipText()
                    }
                }
                .tint(Color(hex: "D2B96A"))

                if hydrateOwnWay {
                    HStack {
                        Text("Final hydration")
                            .font(.jakarta(.regular, size: 17))
                        Spacer()
                        TextField("\(Int(finalHydration * 100))", text: $hydrationText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 72)
                            .font(.jakarta(.regular, size: 17))
                            .padding(.vertical, 4).padding(.horizontal, 4)
                            .background(Color(hex: "F0EDE4"))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                            .onChange(of: hydrationText) { _, val in
                                let f = val.filter { $0.isNumber || $0 == "." }
                                if f != val { hydrationText = f; return }
                                if let d = Double(val), d >= 1 { finalHydration = d / 100 }
                            }
                        Text("%").foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Final hydration")
                                .font(.jakarta(.regular, size: 17))
                            Spacer()
                            TextField("\(Int(styleDefault * 100))", text: $hydrationText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 52)
                                .font(.jakarta(.regular, size: 17))
                                .padding(.vertical, 4).padding(.horizontal, 4)
                                .background(Color(hex: "F0EDE4"))
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                                .onChange(of: hydrationText) { _, val in
                                    let f = val.filter { $0.isNumber || $0 == "." }
                                    if f != val { hydrationText = f; return }
                                    if let d = Double(val), d > 0 { finalHydration = min(d / 100, 0.90) }
                                }
                            Text("%").foregroundColor(.secondary)
                        }

                        Slider(value: $finalHydration, in: 0.50...0.90, step: 0.01)
                            .tint(Color(hex: "D2B96A"))
                            .onChange(of: finalHydration) { _, val in
                                hydrationText = "\(Int(val * 100))"
                            }

                        HStack(spacing: 0) {
                            ForEach(hydrationZones, id: \.label) { zone in
                                Text(zone.label)
                                    .font(.jakarta(.regular, size: 9))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(zone.active ? Color(hex: "D2B96A") : Color.secondary.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Water")
            } footer: {
                Group {
                    if hydrateOwnWay {
                        Text("Slider hidden â€” any value from 1â€“999% accepted. The formula scales accordingly.")
                    } else if isFromConversion {
                        Text("Pre-filled from your volume recipe  Â·  higher = stickier dough, more open crumb  Â·  tap field to type any value")
                    } else {
                        Text("Style default: \(Int(styleDefault * 100))%  Â·  higher = stickier dough, more open crumb  Â·  tap field to type any value")
                    }
                }
                .font(.jakarta(.regular, size: 11))
                .tipText()
            }
            .listRowBackground(Color.clear)

            Section {
                HStack {
                    Text("Salt")
                        .font(.jakarta(.regular, size: 17))
                    Spacer()
                    TextField("2.8", text: $saltText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 52)
                        .font(.jakarta(.regular, size: 17))
                        .padding(.vertical, 4).padding(.horizontal, 4)
                        .background(Color(hex: "F0EDE4"))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                        .onChange(of: saltText) { _, val in
                            let f = val.filter { $0.isNumber || $0 == "." }
                            if f != val { saltText = f; return }
                            if let d = Double(val), d > 0 { saltPct = d / 100 }
                        }
                    Text("%").foregroundColor(.secondary)
                }
            } header: {
                Text("Salt")
            } footer: {
                Group {
                    if isFromConversion {
                        Text("Pre-filled from your volume recipe  Â·  typical: 2.5â€“3%")
                    } else {
                        Text("Typical: 2.5â€“3% of flour weight")
                    }
                }
                .font(.jakarta(.regular, size: 11))
                .tipText()
            }
            .listRowBackground(Color.clear)

            Section {
                Picker("Type", selection: $yeastType) {
                    ForEach(YeastType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .font(.jakarta(.regular, size: 17))

                HStack {
                    Text("Quantity")
                        .font(.jakarta(.regular, size: 17))
                    Spacer()
                    TextField("0.1", text: $yeastText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 52)
                        .font(.jakarta(.regular, size: 17))
                        .padding(.vertical, 4).padding(.horizontal, 4)
                        .background(Color(hex: "F0EDE4"))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
                        .onChange(of: yeastText) { _, val in
                            let f = val.filter { $0.isNumber || $0 == "." }
                            if f != val { yeastText = f; return }
                            if let d = Double(val), d > 0 { yeastPct = d / 100 }
                        }
                    Text("%").foregroundColor(.secondary)
                }
            } header: {
                Text("Yeast")
            } footer: {
                Group {
                    if isFromConversion {
                        Text("Pre-filled from your volume recipe  Â·  \(yeastType.typicalRange)")
                    } else {
                        Text(yeastType.typicalRange)
                    }
                }
                .font(.jakarta(.regular, size: 11))
                .tipText()
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            hydrationText = "\(Int(finalHydration * 100))"
            saltText      = String(format: "%.1f", saltPct * 100)
            yeastText     = String(format: "%.2f", yeastPct * 100)
        }
    }

    struct HydrationZone { let label: String; let active: Bool }
    var hydrationZones: [HydrationZone] {
        let zones      = ["Stiff\nâ‰¤58%", "Standard\n59â€“65%", "High\n66â€“72%", "Very High\n73â€“80%", "Slack\n81%+"]
        let thresholds: [ClosedRange<Double>] = [
            0.50...0.585, 0.585...0.655, 0.655...0.725, 0.725...0.805, 0.805...0.90
        ]
        return zip(zones, thresholds).map { HydrationZone(label: $0, active: $1.contains(finalHydration)) }
    }
}
