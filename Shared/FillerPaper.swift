import SwiftUI

// MARK: - Palette

extension Color {
    static let paperWhite  = Color(hex: "FAFAF8")
    static let paperRule   = Color(hex: "C2D4E4")
    static let paperMargin = Color(hex: "D94545")
    static let paperHeader = Color(hex: "8AAEC8")
}

// MARK: - Metrics

enum PM {
    static let marginX:     CGFloat = 12
    static let lineSpacing: CGFloat = 32
}

// MARK: - Ruled background

/// Ruled paper canvas — blue horizontal lines + red vertical margin.
/// Extends downward into the home indicator safe area only.
/// Does NOT extend upward — caller controls top alignment via VStack.
struct RuledPaperBackground: View {
    var body: some View {
        Canvas { context, size in
            // Paper base
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.paperWhite)
            )
            // Horizontal rules
            let count = Int(size.height / PM.lineSpacing) + 2
            for i in 0..<count {
                let y = CGFloat(i) * PM.lineSpacing + PM.lineSpacing * 0.75
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.paperRule), lineWidth: 0.5)
            }
            // Red margin line
            var margin = Path()
            margin.move(to:    CGPoint(x: PM.marginX, y: 0))
            margin.addLine(to: CGPoint(x: PM.marginX, y: size.height))
            context.stroke(margin, with: .color(.paperMargin), lineWidth: 1.2)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

// MARK: - Header band

/// The blue header band that sits between the nav bar and the scrollable content.
/// Carries the view title in a large serif font, with the red margin line running through it.
struct FillerPaperHeaderBand: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.paperMargin)
                .frame(width: 1.2)
                .padding(.leading, PM.marginX)

            Text(title)
                .font(.system(size: 24, design: .serif))
                .foregroundColor(Color.paperWhite)
                .lineLimit(2)
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 14)

            Spacer()
        }
        .background(Color.paperHeader)
    }
}

// MARK: - View modifier

/// Applies the filler-paper theme via a VStack — header band fixed above content,
/// ruled paper canvas behind the scrollable area. No safeAreaInset used.
struct FillerPaperModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            FillerPaperHeaderBand(title: title)
            ZStack(alignment: .topLeading) {
                RuledPaperBackground()
                content
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.paperHeader, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func fillerPaper(title: String) -> some View {
        modifier(FillerPaperModifier(title: title))
    }
}
