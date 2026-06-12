import SwiftUI

struct TechniqueStepView: View {
    @Binding var mixerType: MixerType
    @Binding var autolyse: Bool
    @Binding var bassinage: Bool
    @Binding var autolyseMinutes: Int
    @Binding var customMixerName: String
    @Binding var mixingNotes: String
    let style: PizzaStyle
    let finalHydration: Double

    var body: some View {
        List {
            Section { WizardProgressView(step: 6, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section(header: Text("How will you mix?").font(.jakarta(.semibold, size: 13))) {
                ForEach(MixerType.allCases, id: \.self) { mixer in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mixer.rawValue).font(.jakarta(.semibold, size: 17))
                            if !mixer.note.isEmpty {
                                Text(mixer.note).font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if mixerType == mixer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "7FA2BD"))
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { mixerType = mixer }
                }

                if mixerType == .other {
                    TextField("Describe your mixer", text: $customMixerName)
                        .font(.jakarta(.regular, size: 17))
                        .textFieldBox()
                        .padding(.top, 2)
                }
            }
            .listRowBackground(Color.clear)

            if finalHydration > 0.70 && mixerType == .hand {
                Section {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow).font(.jakarta(.regular, size: 12)).padding(.top, 2)
                        Text("At \(Int(finalHydration * 100))% hydration, hand mixing will be challenging. Budget extra time and use wet hands.")
                            .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.yellow.opacity(0.08))
                .tipText()
            }

            Section {
                Toggle(isOn: $autolyse) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Autolyse").font(.jakarta(.semibold, size: 17))
                        Text("Rest flour + water before adding salt and yeast. Improves extensibility.")
                            .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                            .tipText()
                    }
                }
                .tint(Color(hex: "7FA2BD"))

                if autolyse {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rest time")
                                .font(.jakarta(.regular, size: 17))
                            Text("suggested: \(style == .neapolitan ? 20 : 30) min")
                                .font(.jakarta(.regular, size: 11))
                                .foregroundColor(.secondary)
                                .tipText()
                        }
                        Spacer()
                        TextField("\(style == .neapolitan ? 20 : 30)",
                                  value: $autolyseMinutes,
                                  format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 52)
                            .font(.jakarta(.regular, size: 17))
                            .inputBox()
                        Text("min").foregroundColor(.secondary)
                    }
                }
            }
            .listRowBackground(Color.clear)

            Section {
                Toggle(isOn: $bassinage) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bassinage").font(.jakarta(.semibold, size: 17))
                        Text("Reserve a portion of water and add gradually during kneading. Controls temperature and improves extensibility.")
                            .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                            .tipText()
                    }
                }
                .tint(Color(hex: "7FA2BD"))

                if bassinage {
                    LabeledContent("Default reserve", value: "10% of total water")
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.secondary)
                    Text("Adjustable per process step in the next screen.")
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                        .tipText()
                }
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Mixing notes").font(.jakarta(.semibold, size: 13))) {
                TextField("Any notes for this stage...", text: $mixingNotes, axis: .vertical)
                    .font(.jakarta(.regular, size: 13))
                    .lineLimit(3...)
                    .notesBox()
            }
            .listRowBackground(Color.clear)
        }
        .meadList()
    }
}
