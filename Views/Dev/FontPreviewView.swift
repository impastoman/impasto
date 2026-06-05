// FontPreviewView.swift
// DROP INTO Xcode, run in Preview or Simulator.
// DELETE before shipping — dev only.

import SwiftUI

// MARK: - Font helpers (remove once wired into ImpastoStyle)

private extension Font {
    // Plus Jakarta Sans
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium:    name = "PlusJakartaSans-Medium"
        case .semibold:  name = "PlusJakartaSans-SemiBold"
        case .bold:      name = "PlusJakartaSans-Bold"
        case .light:     name = "PlusJakartaSans-Light"
        case .extraBold,
             .heavy:     name = "PlusJakartaSans-ExtraBold"
        default:         name = "PlusJakartaSans-Regular"
        }
        return .custom(name, size: size)
    }

    // Fraunces
    static func fraunces(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "Fraunces-Italic" : "Fraunces-Regular", size: size)
    }
    static func frauncesLight(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "Fraunces-LightItalic" : "Fraunces-Light", size: size)
    }
    static func frauncesSemiBold(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "Fraunces-SemiBoldItalic" : "Fraunces-SemiBold", size: size)
    }
}

// MARK: - Palette

private extension Color {
    static let paper       = Color(hex: "F5F1E8")
    static let paperDeep   = Color(hex: "F0EDE4")
    static let ink         = Color(hex: "2C2A24")
    static let inkLight    = Color(hex: "9A9688")
    static let gold        = Color(hex: "D2B96A")
    static let goldFaint   = Color(hex: "D2B96A").opacity(0.15)
    static let rule        = Color(hex: "C4B89A").opacity(0.35)
    static let headerBand  = Color(hex: "8AAEC8")
}

// MARK: - Root

struct FontPreviewView: View {
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.paper.ignoresSafeArea()
            ruledLines

            VStack(spacing: 0) {
                // Header band
                ZStack {
                    Color.headerBand.ignoresSafeArea(edges: .top)
                    Text("Font Preview")
                        .font(.jakarta(13, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(1.5)
                        .padding(.bottom, 10)
                        .padding(.top, 6)
                }
                .frame(height: 44)

                // Tab bar
                HStack(spacing: 0) {
                    tabButton("Fraunces", index: 0)
                    tabButton("Jakarta Sans", index: 1)
                    tabButton("In Context", index: 2)
                }
                .background(Color.paperDeep)
                .overlay(Divider(), alignment: .bottom)

                ScrollView {
                    switch tab {
                    case 0:  FrauncesPanel()
                    case 1:  JakartaPanel()
                    default: ContextPanel()
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    func tabButton(_ label: String, index: Int) -> some View {
        Button { tab = index } label: {
            VStack(spacing: 0) {
                Text(label)
                    .font(.jakarta(11, weight: tab == index ? .semibold : .regular))
                    .foregroundColor(tab == index ? Color.gold : Color.inkLight)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(tab == index ? Color.gold : Color.clear)
                    .frame(height: 2)
            }
        }
    }

    var ruledLines: some View {
        GeometryReader { geo in
            let lineCount = Int(geo.size.height / 28) + 2
            VStack(spacing: 0) {
                ForEach(0..<lineCount, id: \.self) { _ in
                    Spacer()
                    Divider().background(Color.rule)
                        .frame(height: 0.5)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Fraunces panel

private struct FrauncesPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Display / Headlines")

            sample(
                label: "Light  ·  36pt",
                view: AnyView(
                    Text("Neapolitan")
                        .font(.frauncesLight(36))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Regular  ·  36pt",
                view: AnyView(
                    Text("Neapolitan")
                        .font(.fraunces(36))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "SemiBold  ·  36pt",
                view: AnyView(
                    Text("Neapolitan")
                        .font(.frauncesSemiBold(36))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Regular Italic  ·  36pt",
                view: AnyView(
                    Text("Neapolitan")
                        .font(.fraunces(36, italic: true))
                        .foregroundColor(.ink)
                )
            )

            dividerRow()
            sectionHeader("App title / Wordmark")

            sample(
                label: "Light  ·  52pt — current system serif",
                view: AnyView(
                    Text("Stesura")
                        .font(.system(size: 52, design: .serif))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Light  ·  52pt — Fraunces",
                view: AnyView(
                    Text("Stesura")
                        .font(.frauncesLight(52))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Regular  ·  52pt — Fraunces",
                view: AnyView(
                    Text("Stesura")
                        .font(.fraunces(52))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Italic  ·  52pt — Fraunces",
                view: AnyView(
                    Text("Stesura")
                        .font(.fraunces(52, italic: true))
                        .foregroundColor(.ink)
                )
            )

            dividerRow()
            sectionHeader("Recipe names  ·  20–24pt")

            sample(
                label: "Light  ·  22pt",
                view: AnyView(
                    Text("72hr Cold Ferment Neapolitan")
                        .font(.frauncesLight(22))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Regular  ·  22pt",
                view: AnyView(
                    Text("72hr Cold Ferment Neapolitan")
                        .font(.fraunces(22))
                        .foregroundColor(.ink)
                )
            )
            sample(
                label: "Italic  ·  22pt",
                view: AnyView(
                    Text("72hr Cold Ferment Neapolitan")
                        .font(.fraunces(22, italic: true))
                        .foregroundColor(.ink)
                )
            )

            dividerRow()
            sectionHeader("Body / Paragraph  ·  15–16pt")

            sample(
                label: "Regular  ·  15pt",
                view: AnyView(
                    Text("Place dough into a lightly oiled container, cover, and rest at room temperature. Perform stretch and fold every 30 minutes.")
                        .font(.fraunces(15))
                        .foregroundColor(.ink)
                        .lineSpacing(4)
                )
            )
            sample(
                label: "Light  ·  15pt",
                view: AnyView(
                    Text("Place dough into a lightly oiled container, cover, and rest at room temperature. Perform stretch and fold every 30 minutes.")
                        .font(.frauncesLight(15))
                        .foregroundColor(.ink)
                        .lineSpacing(4)
                )
            )

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Jakarta Sans panel

private struct JakartaPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Weight ladder  ·  17pt")

            sample(label: "Light  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .light)).foregroundColor(.ink)))
            sample(label: "Regular  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17)).foregroundColor(.ink)))
            sample(label: "Medium  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .medium)).foregroundColor(.ink)))
            sample(label: "SemiBold  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .semibold)).foregroundColor(.ink)))
            sample(label: "Bold  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .bold)).foregroundColor(.ink)))
            sample(label: "ExtraBold  ·  17pt",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .extraBold)).foregroundColor(.ink)))

            dividerRow()
            sectionHeader("vs. current system monospaced  ·  17pt")

            sample(label: "System monospaced — current",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(.regular, size: 17)).foregroundColor(.ink)))
            sample(label: "Jakarta Regular — proposed",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17)).foregroundColor(.ink)))
            sample(label: "Jakarta Medium — proposed",
                   view: AnyView(Text("Bulk Fermentation").font(.jakarta(17, weight: .medium)).foregroundColor(.ink)))

            dividerRow()
            sectionHeader("Small UI text  ·  11–13pt")

            sample(label: "Regular  ·  11pt — section footer",
                   view: AnyView(Text("Optional — save this blend for reuse in future recipes").font(.jakarta(11)).foregroundColor(.inkLight)))
            sample(label: "Regular  ·  12pt — step label",
                   view: AnyView(Text("STRETCH & FOLD  ·  45M").font(.jakarta(12)).foregroundColor(.inkLight).tracking(0.8)))
            sample(label: "SemiBold  ·  12pt — step label",
                   view: AnyView(Text("STRETCH & FOLD  ·  45M").font(.jakarta(12, weight: .semibold)).foregroundColor(.inkLight).tracking(0.8)))
            sample(label: "Medium  ·  13pt — list row",
                   view: AnyView(Text("Preview Recipe →").font(.jakarta(13, weight: .medium)).foregroundColor(.gold)))

            dividerRow()
            sectionHeader("Numbers  ·  Timer / Weights")

            sample(label: "Regular  ·  28pt — timer",
                   view: AnyView(Text("00:45:00").font(.jakarta(28)).foregroundColor(.ink)))
            sample(label: "Light  ·  28pt — timer",
                   view: AnyView(Text("00:45:00").font(.jakarta(28, weight: .light)).foregroundColor(.ink)))
            sample(label: "Medium  ·  14pt — session row",
                   view: AnyView(Text("01:23:47").font(.jakarta(14, weight: .medium)).foregroundColor(.gold)))

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - In-context panel

private struct ContextPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // --- Home screen wordmark ---
            sectionHeader("Home screen wordmark")
            VStack(spacing: 4) {
                ZStack {
                    Color.paper
                    VStack(spacing: 6) {
                        Text("Stesura")
                            .font(.fraunces(52))
                            .foregroundColor(Color(hex: "2C2A24"))
                        Text("Dough Manager")
                            .font(.jakarta(11, weight: .regular))
                            .foregroundColor(Color(hex: "9A9688"))
                            .tracking(2)
                        Text("v0.9")
                            .font(.jakarta(10))
                            .foregroundColor(Color(hex: "C4B89A"))
                    }
                    .padding(.vertical, 32)
                }
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rule, lineWidth: 1))
            }

            // --- Recipe card ---
            sectionHeader("Recipe card header")
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "8AAEC8")
                    HStack {
                        Text("72hr Cold Ferment")
                            .font(.fraunces(20))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .cornerRadius(10, corners: [.topLeft, .topRight])

                VStack(spacing: 0) {
                    contextRow(label: "Style", value: "Neapolitan")
                    Divider().padding(.leading, 16)
                    contextRow(label: "Method", value: "Hand-kneaded")
                    Divider().padding(.leading, 16)
                    contextRow(label: "Timeline", value: "72 hr · 3 days")
                    Divider().padding(.leading, 16)
                    contextRow(label: "Target", value: "4 × 280g")
                }
                .background(Color.paperDeep)
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rule, lineWidth: 1))
            }

            // --- Process step row ---
            sectionHeader("Live session step")
            VStack(spacing: 0) {
                ZStack {
                    Color.paperDeep
                    VStack(spacing: 2) {
                        Text("Bulk Fermentation")
                            .font(.fraunces(24))
                            .foregroundColor(Color(hex: "2C2A24"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("8 hours remaining")
                            .font(.jakarta(12))
                            .foregroundColor(Color(hex: "9A9688"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                }

                ZStack {
                    Color.paper
                    HStack {
                        Text("07:58:34")
                            .font(.jakarta(34, weight: .light))
                            .foregroundColor(Color(hex: "D2B96A"))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("– 0:01:26")
                                .font(.jakarta(13, weight: .medium))
                                .foregroundColor(Color(hex: "6DBF8A"))
                            Text("under")
                                .font(.jakarta(10))
                                .foregroundColor(Color(hex: "9A9688"))
                        }
                    }
                    .padding(16)
                }
            }
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rule, lineWidth: 1))

            // --- Wizard section header ---
            sectionHeader("Wizard section header")
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "8AAEC8")
                    HStack {
                        Text("New Recipe")
                            .font(.fraunces(18))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Step 3 of 10")
                            .font(.jakarta(11))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .cornerRadius(10, corners: [.topLeft, .topRight])

                VStack(spacing: 0) {
                    contextRow(label: "Flour type", value: "00 Flour")
                    Divider().padding(.leading, 16)
                    contextRow(label: "Percentage", value: "100%")
                    Divider().padding(.leading, 16)
                    contextRow(label: "Gluten", value: "12.5%")
                }
                .background(Color.paperDeep)
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rule, lineWidth: 1))
            }

            // --- Mixed: Fraunces titles + Jakarta body ---
            sectionHeader("Mixed pairing — recommended")
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                    Color.paperDeep.cornerRadius(10)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Autolyse")
                            .font(.fraunces(20))
                            .foregroundColor(Color(hex: "2C2A24"))
                        Text("Mix flour and water, hold back salt and yeast. Rest covered for 20–60 minutes before adding remaining ingredients.")
                            .font(.jakarta(14))
                            .foregroundColor(Color(hex: "2C2A24"))
                            .lineSpacing(3)
                        HStack {
                            Text("Duration")
                                .font(.jakarta(12))
                                .foregroundColor(Color(hex: "9A9688"))
                            Spacer()
                            Text("30 min")
                                .font(.jakarta(12, weight: .medium))
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                    .padding(16)
                }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rule, lineWidth: 1))
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
    }

    func contextRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.jakarta(14))
                .foregroundColor(Color(hex: "9A9688"))
            Spacer()
            Text(value)
                .font(.jakarta(14, weight: .medium))
                .foregroundColor(Color(hex: "2C2A24"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Shared helpers

private func sectionHeader(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.jakarta(9, weight: .semibold))
        .foregroundColor(Color(hex: "9A9688"))
        .tracking(1.5)
        .padding(.top, 20)
        .padding(.bottom, 6)
}

private func dividerRow() -> some View {
    Divider()
        .background(Color(hex: "C4B89A").opacity(0.5))
        .padding(.vertical, 8)
}

private func sample(label: String, view: AnyView) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(label)
            .font(.jakarta(9))
            .foregroundColor(Color(hex: "C4B89A"))
            .tracking(0.5)
        view
            .padding(.vertical, 2)
        Divider().background(Color(hex: "C4B89A").opacity(0.25))
    }
    .padding(.vertical, 4)
}

// MARK: - Corner radius helper

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    FontPreviewView()
}
