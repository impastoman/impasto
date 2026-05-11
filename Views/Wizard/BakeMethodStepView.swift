import SwiftUI

struct BakeMethodStepView: View {
    @Binding var bakeSetups: [BakeSetup]

    var body: some View {
        List {
            Section { WizardProgressView(step: 8, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section {
                ForEach(BakeMethod.allCases, id: \.self) { method in
                    let isSelected = bakeSetups.contains { $0.method == method }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.rawValue).font(.headline)
                            if !method.subMethods.isEmpty {
                                Text(method.subMethods.joined(separator: " · "))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? Color(hex: "D2B96A") : .secondary)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelected {
                            bakeSetups.removeAll { $0.method == method }
                        } else {
                            bakeSetups.append(BakeSetup(method: method))
                        }
                    }
                }
            } header: {
                Text("Select all that apply")
            } footer: {
                Text("You can save settings for multiple setups — choose which to use at pre-flight.")
                    .font(.system(size: 11, design: .monospaced))
            }

            ForEach($bakeSetups) { $setup in
                BakeSetupDetailSection(setup: $setup)
            }
        }
    }
}

private struct BakeSetupDetailSection: View {
    @Binding var setup: BakeSetup

    var body: some View {
        Section {
            if setup.method == .portableOven {
                HStack {
                    Text("Setup")
                    Spacer()
                    TextField("Oven brand & model", text: $setup.subMethod)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.body, design: .monospaced))
                }
            } else if !setup.method.subMethods.isEmpty {
                Picker("Setup", selection: $setup.subMethod) {
                    Text("Select…").tag("")
                    ForEach(setup.method.subMethods, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }

            HStack {
                Text("Preheat")
                Spacer()
                TextField("45", value: $setup.preheatMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))
                Text("min").foregroundColor(.secondary)
            }

            HStack {
                Text("Oven temp")
                Spacer()
                TextField("260", value: $setup.ovenTempMin, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))
                Text("–")
                TextField("290", value: $setup.ovenTempMax, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))
                Text(setup.tempUnit).foregroundColor(.secondary)
            }

            if setup.method.hasSurfaceTemp {
                HStack {
                    Text("Surface temp")
                    Spacer()
                    TextField("optional", value: $setup.surfaceTemp, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                        .font(.system(.body, design: .monospaced))
                    Text(setup.tempUnit).foregroundColor(.secondary)
                }
            }

            Picker("Temperature unit", selection: $setup.useCelsius) {
                Text("°F  Fahrenheit").tag(false)
                Text("°C  Celsius").tag(true)
            }
            .font(.system(size: 13, design: .monospaced))

            TextField("Notes", text: $setup.notes, axis: .vertical)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(2...)
        } header: {
            Text(setup.method.rawValue)
        }
    }
}
