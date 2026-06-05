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
                            Text(method.displayName).font(.jakarta(.semibold, size: 17))
                            if !method.subMethods.isEmpty {
                                Text(method.subMethods.joined(separator: " · "))
                                    .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
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
                Text("Baking method")
            } footer: {
                Text("You can save settings for multiple setups — choose which to use at prep.")
                    .font(.jakarta(.regular, size: 11))
                    .tipText()
            }
            .listRowBackground(Color.clear)

            ForEach($bakeSetups) { $setup in
                BakeSetupDetailSection(setup: $setup)
            }
        }
        .scrollContentBackground(.hidden)
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
                        .font(.jakarta(.regular, size: 17))
                        .inputBox()
                }
            } else if !setup.method.subMethods.isEmpty {
                Picker("Setup", selection: $setup.subMethod) {
                    Text("Select…").tag("")
                    ForEach(setup.method.subMethods, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                .font(.jakarta(.regular, size: 17))
            }

            HStack {
                Text("Preheat")
                Spacer()
                TextField("45", value: $setup.preheatMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .font(.jakarta(.regular, size: 17))
                    .inputBox()
                Text("min").foregroundColor(.secondary)
            }

            HStack {
                Text("Oven temp")
                Spacer()
                TextField("260", value: $setup.ovenTempMin, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .font(.jakarta(.regular, size: 17))
                    .inputBox()
                Text("–")
                TextField("290", value: $setup.ovenTempMax, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .font(.jakarta(.regular, size: 17))
                    .inputBox()
                Text(setup.tempUnit).foregroundColor(.secondary)
            }

            if setup.method.hasSurfaceTemp {
                HStack {
                    Text("Surface temp")
                    Spacer()
                    TextField("optional", value: $setup.surfaceTemp, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 64)
                        .font(.jakarta(.regular, size: 17))
                        .inputBox()
                    Text(setup.tempUnit).foregroundColor(.secondary)
                }
            }

            Picker("Temperature unit", selection: $setup.useCelsius) {
                Text("°F  Fahrenheit").tag(false)
                Text("°C  Celsius").tag(true)
            }
            .font(.jakarta(.regular, size: 13))

            TextField("Notes", text: $setup.notes, axis: .vertical)
                .font(.jakarta(.regular, size: 13))
                .lineLimit(2...)
                .notesBox()
        } header: {
            Text(setup.method.displayName)
        }
        .listRowBackground(Color.clear)
    }
}
