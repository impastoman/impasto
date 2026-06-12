import SwiftUI
import PhotosUI

// MARK: - Custom fonts
//
// Fraunces — expressive serif. Used for display / title surfaces (welcome
// logo, big section headers, recipe-detail titles). Has multiple optical
// sizes; we use the standard family.
//
// Plus Jakarta Sans — clean humanist sans. Used for body text, labels,
// buttons, tips, secondary copy.
//
// System monospaced — kept for numeric values, timers, tabular columns
// where alignment matters more than personality.
//
// Wire fonts via these helpers rather than hardcoding PostScript names
// at call sites. One place to update if we ever swap families.

// MARK: - Mead notebook palette
//
// Stesura's visual identity: wide-ruled Mead notebook paper. Soft warm
// off-white "paper", thin cool-blue rule lines on every divider and
// border, and warm muted red for emphasis (the teacher's red pen).
//
// Use the named constants rather than raw hex strings so the palette
// can be tuned in one place.

// MARK: - Mead notebook List modifiers
//
// Three composable helpers to apply the notebook treatment to any
// SwiftUI List in the app. Apply at the three layers:
//   .meadList()    on the List itself  — red margin background + tight section spacing
//   .meadSection() on each Section     — blue inter-row separator tint
//   .meadRow()     on each row builder — pulls the blue separator's leading edge
//                                         into the inset zone so it meets the red strip flush
//
// All three are idempotent and safe to chain; they apply only their
// own modifier and don't touch any other styling.

extension View {
    /// Applies the Mead-paper background to a List: hides the system
    /// content background, paints a continuous 1pt teacher's-red margin
    /// strip behind the rows at the leading edge, compacts section
    /// spacing, and (optimistically) tints inter-row separators to
    /// rule-blue at the List level. The List-level tint cascades to all
    /// rows ONLY in static Section layouts; for Lists with a dynamic
    /// ForEach producing Sections (e.g. LibraryView), per-Section
    /// .meadSection() is still required.
    func meadList() -> some View {
        self
            .scrollContentBackground(.hidden)
            // Draw the margin line as an OVERLAY (on top of rows), not a
            // background. Most Lists use opaque default row backgrounds
            // that paint over a background strip, leaving the red showing
            // only in the gaps between sections (the "broken line" bug).
            // An overlay draws in front of row content; at 1pt in the
            // x=20 inset gutter it never touches text, and
            // .allowsHitTesting(false) keeps taps/swipes reaching rows.
            .overlay(alignment: .leading) {
                Color.marginRed
                    .frame(width: 1)
                    .padding(.leading, 20)
                    .allowsHitTesting(false)
            }
            .listSectionSpacing(.compact)
            .listRowSeparatorTint(Color.ruleBlue)
    }

    /// Tints all inter-row separators in a Section to rule-blue. Per
    /// Apple's docs, applying .listRowSeparatorTint to a Section
    /// cascades to every row inside it.
    func meadSection() -> some View {
        self.listRowSeparatorTint(Color.ruleBlue)
    }

    /// Pulls the row separator's leading edge 12pt left into the row's
    /// inset area so it meets the red margin strip flush. Apply this to
    /// each row's content view, not the row container.
    func meadRow() -> some View {
        self.alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] - 12 }
    }
}

extension Color {
    /// App background + card backgrounds. Soft off-white, slightly warm.
    static let paperWhite     = Color(hex: "FAFAF5")
    /// Every line, divider, border, field outline.
    static let ruleBlue       = Color(hex: "7FA2BD")
    /// Subtle blue fills — alternating rows, hover states, picker bg.
    static let ruleBlueFaint  = Color(hex: "C5D6E2")
    /// Margin lines, emphasis, primary action surfaces, warnings.
    static let marginRed      = Color(hex: "D4756A")
    /// Soft red surface for warning sections.
    static let marginRedFaint = Color(hex: "EDD8D3")
    /// Primary text (kept from prior palette).
    static let stesuraInk     = Color(hex: "2C2A24")
    /// Secondary text (kept from prior palette).
    static let stesuraInkSoft = Color(hex: "9A9688")
}

extension Font {
    enum FrauncesWeight {
        case thin, light, regular, semibold, bold, black
        case thinItalic, lightItalic, italic, semiboldItalic, boldItalic, blackItalic

        var psName: String {
            switch self {
            case .thin:           return "Fraunces-Thin"
            case .light:          return "Fraunces-Light"
            case .regular:        return "Fraunces-Regular"
            case .semibold:       return "Fraunces-SemiBold"
            case .bold:           return "Fraunces-Bold"
            case .black:          return "Fraunces-9ptBlack"
            case .thinItalic:     return "Fraunces-ThinItalic"
            case .lightItalic:    return "Fraunces-LightItalic"
            case .italic:         return "Fraunces-Italic"
            case .semiboldItalic: return "Fraunces-SemiBoldItalic"
            case .boldItalic:     return "Fraunces-BoldItalic"
            case .blackItalic:    return "Fraunces-9ptBlackItalic"
            }
        }
    }

    enum JakartaWeight {
        case extraLight, light, regular, medium, semibold, bold, extraBold
        case extraLightItalic, lightItalic, italic, mediumItalic, semiboldItalic, boldItalic, extraBoldItalic

        /// PostScript names come from the variable-font's static fallback
        /// dump. The naming convention is unusual (`-Regular_Bold` etc.)
        /// but accurate as installed.
        var psName: String {
            switch self {
            case .extraLight:        return "PlusJakartaSans-Regular_ExtraLight"
            case .light:             return "PlusJakartaSans-Regular_Light"
            case .regular:           return "PlusJakartaSans-Regular"
            case .medium:            return "PlusJakartaSans-Regular_Medium"
            case .semibold:          return "PlusJakartaSans-Regular_SemiBold"
            case .bold:              return "PlusJakartaSans-Regular_Bold"
            case .extraBold:         return "PlusJakartaSans-Regular_ExtraBold"
            case .extraLightItalic:  return "PlusJakartaSans-Italic_ExtraLight-Italic"
            case .lightItalic:       return "PlusJakartaSans-Italic_Light-Italic"
            case .italic:            return "PlusJakartaSans-Italic"
            case .mediumItalic:      return "PlusJakartaSans-Italic_Medium-Italic"
            case .semiboldItalic:    return "PlusJakartaSans-Italic_SemiBold-Italic"
            case .boldItalic:        return "PlusJakartaSans-Italic_Bold-Italic"
            case .extraBoldItalic:   return "PlusJakartaSans-Italic_ExtraBold-Italic"
            }
        }
    }

    /// Fraunces — serif. Display + title surfaces.
    static func fraunces(_ weight: FrauncesWeight = .regular, size: CGFloat) -> Font {
        .custom(weight.psName, size: size)
    }

    /// Plus Jakarta Sans — sans. Body text + labels + buttons.
    static func jakarta(_ weight: JakartaWeight = .regular, size: CGFloat) -> Font {
        .custom(weight.psName, size: size)
    }
}

// MARK: - Shared field styling

extension View {
    /// Small box for inline number / short-text fields
    func inputBox() -> some View {
        self
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "7FA2BD").opacity(0.5), lineWidth: 1))
    }

    /// Full-width box for notes / multiline text fields
    func notesBox() -> some View {
        self
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "7FA2BD").opacity(0.4), lineWidth: 1))
    }

    /// Standard box for full-width single-line text fields (names, etc.)
    func textFieldBox() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "7FA2BD").opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Camera picker (UIImagePickerController)

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.imageData = img?.jpegData(compressionQuality: 0.85)
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - Library picker (PHPickerViewController)

struct LibraryPickerView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LibraryPickerView
        init(_ parent: LibraryPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage {
                    DispatchQueue.main.async { self.parent.imageData = img.jpegData(compressionQuality: 0.85) }
                }
            }
        }
    }
}

struct StesuraButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jakarta(.semibold, size: 14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            // Filled = margin-red ("do this" emphasis). Outlined = paper
            // with ruleBlue border ("here's an option").
            .background(filled ? Color.marginRed : Color.clear)
            .foregroundColor(filled ? Color.white : Color.stesuraInk)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(filled ? Color.clear : Color.ruleBlue, lineWidth: 1)
            )
            .cornerRadius(6)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

// MARK: - Keyboard dismiss

extension View {
    /// Adds a "Done" button to the top-right of the keyboard toolbar.
    /// Apply to any view containing numberPad / decimalPad text fields.
    func keyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .font(.jakarta(.regular, size: 14))
                .foregroundColor(Color(hex: "7FA2BD"))
            }
        }
    }
}

// MARK: - Tap-anywhere-to-dismiss-keyboard
//
// Installs a UIKit tap gesture recognizer on every window in the active
// scene. The recognizer calls endEditing(_:) on the window, which dismisses
// any active first responder (i.e. closes the keyboard).
//
// `cancelsTouchesInView = false` means the tap still flows through to
// SwiftUI buttons / list rows / TextFields — so focusing a different field
// works normally (the previous keyboard dismisses, then the newly tapped
// field opens its own). Tapping outside any field just dismisses.

extension UIApplication {
    /// Call once at app startup (e.g. from the App's init or the root view's
    /// onAppear) to install global tap-outside-to-dismiss-keyboard behavior.
    func installDismissKeyboardOnTap() {
        guard let scene = connectedScenes.first as? UIWindowScene else { return }
        for window in scene.windows {
            // Avoid double-installing across hot reloads / multiple onAppear fires.
            if window.gestureRecognizers?.contains(where: { $0.name == "StesuraDismissKeyboardTap" }) == true {
                continue
            }
            let tap = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing(_:)))
            tap.name = "StesuraDismissKeyboardTap"
            tap.cancelsTouchesInView = false
            tap.requiresExclusiveTouchType = false
            window.addGestureRecognizer(tap)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Tip gating
//
// Wrap any "grey caption tip" — explanatory helper text under a field, a
// Section footer, an inline warning — with `.tipText()`. When the user
// turns off "Show tips" in Settings, the view collapses to EmptyView()
// so only field labels remain.
//
// Usage:
//   Text("Optional — save this for reuse")
//       .font(.jakarta(.regular, size: 11))
//       .foregroundColor(.secondary)
//       .tipText()

private struct TipGateModifier: ViewModifier {
    @AppStorage("showTips") private var showTips: Bool = true
    func body(content: Content) -> some View {
        if showTips { content }
    }
}

extension View {
    /// Hides this view when the user has turned off "Show tips" in Settings.
    /// Use only for explainer captions — never for required field labels.
    func tipText() -> some View {
        modifier(TipGateModifier())
    }

    /// Apply a transform conditionally. Useful for gating modifiers like
    /// `.draggable(...)` so they don't fire outside of reorder mode.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Photo gallery (multi-photo with drag-to-reorder + cover badge)
//
// Used in PizzaLogView, PizzaDetailView, BakeLogDetailView, and SessionLogView.
// The first photo (index 0) is treated as the "main thumbnail" / cover and
// gets a gold MAIN badge. Drag any photo onto another to reorder; drop on the
// first slot to make it the cover.

struct PhotoGalleryView: View {
    @Binding var photoIDs: [UUID]
    /// Show per-photo delete (xmark) buttons + the trailing "+ Add" tile.
    var isEditable: Bool = true
    /// Allow drag-to-reorder.
    var allowsReorder: Bool = true
    /// Tap-target for the "+ Add" tile.
    var onAdd: (() -> Void)? = nil
    /// Tap on a photo tile body → opens the full-screen viewer with this index.
    var onTap: ((Int) -> Void)? = nil
    var thumbnailSize: CGFloat = 100

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // ID by the photo's UUID — stable across reorders, no
                // chance of duplicate-Data confusion.
                ForEach(Array(photoIDs.enumerated()), id: \.element) { idx, id in
                    if let uiImage = ImageCache.shared.image(for: id) {
                        photoTile(uiImage: uiImage, idx: idx, id: id)
                    }
                }
                if isEditable, let onAdd = onAdd {
                    addTile(onTap: onAdd)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func photoTile(uiImage: UIImage, idx: Int, id: UUID) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                onTap?(idx)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipped()
                        .cornerRadius(8)
                    if idx == 0 && photoIDs.count > 1 {
                        Text("MAIN")
                            .font(.jakarta(.regular, size: 9))
                            .tracking(1)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.ruleBlue)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                            .padding(5)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil)
            if isEditable {
                Button {
                    PhotoStore.shared.delete(id)
                    ImageCache.shared.invalidate(id)
                    photoIDs.remove(at: idx)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, Color.black.opacity(0.55))
                }
                .padding(4)
            }
        }
        .if(allowsReorder) { tile in
            tile.draggable("\(idx)")
        }
        .if(allowsReorder) { tile in
            tile.dropDestination(for: String.self) { items, _ in
                guard let srcStr = items.first, let srcIdx = Int(srcStr) else { return false }
                movePhoto(from: srcIdx, to: idx)
                return true
            }
        }
    }

    private func addTile(onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundColor(Color.ruleBlue)
                Text("Add")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(Color.ruleBlue)
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .background(Color.ruleBlue.opacity(0.08))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ruleBlue.opacity(0.3), lineWidth: 1))
        }
    }

    private func movePhoto(from src: Int, to dst: Int) {
        guard src != dst,
              photoIDs.indices.contains(src),
              photoIDs.indices.contains(dst) else { return }
        let item = photoIDs.remove(at: src)
        photoIDs.insert(item, at: dst)
    }
}

// MARK: - Full-screen photo viewer + cover picker
//
// Used together with PhotoGalleryView's `onTap`. Tapping a thumbnail
// presents this viewer; if the tapped photo isn't already at index 0,
// the "Make main?" button moves it to position 0 (the cover).
// Persistence happens automatically through the parent's binding setter.

/// Identifiable wrapper so `.fullScreenCover(item:)` can present the viewer
/// keyed on the tapped tile's index. Carries the photo's PhotoStore UUID
/// so the viewer renders via ImageCache (and persistence flows by id, not
/// raw Data).
struct PhotoViewerItem: Identifiable, Equatable {
    let id: Int
    let photoID: UUID
}

struct FullScreenPhotoViewer: View {
    let photoID: UUID
    /// True when this photo is NOT yet the main thumbnail (idx > 0).
    /// When false, the button is replaced by a "Main photo" badge.
    let canMakeMain: Bool
    /// Invoked when the user taps "Make main?". Mutate the source array
    /// in this closure — the viewer will then dismiss itself.
    let onMakeMain: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = ImageCache.shared.image(for: photoID) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            Group {
                if canMakeMain {
                    Button {
                        // Dismiss first, then run the mutation after the
                        // cover finishes transitioning out. Mutating parent
                        // @State while the cover is still presenting causes
                        // SwiftUI to drop the update in some cases.
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onMakeMain()
                        }
                    } label: {
                        Text("Make main?")
                            .font(.jakarta(.regular, size: 13))
                            .tracking(1)
                            .foregroundColor(Color(hex: "7FA2BD"))
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(hex: "7FA2BD"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "7FA2BD"))
                        Text("Main photo")
                            .font(.jakarta(.regular, size: 13))
                            .tracking(1)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}
