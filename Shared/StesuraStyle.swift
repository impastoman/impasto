import SwiftUI
import PhotosUI

// MARK: - Shared field styling

extension View {
    /// Small box for inline number / short-text fields
    func inputBox() -> some View {
        self
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
    }

    /// Full-width box for notes / multiline text fields
    func notesBox() -> some View {
        self
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "D2B96A").opacity(0.4), lineWidth: 1))
    }

    /// Standard box for full-width single-line text fields (names, etc.)
    func textFieldBox() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "F0EDE4"))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "D2B96A").opacity(0.5), lineWidth: 1))
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
            .font(.system(size: 14, design: .monospaced))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(filled ? Color(hex: "D2B96A") : Color.clear)
            .foregroundColor(filled ? Color(hex: "111210") : Color(hex: "9A9688"))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(filled ? Color.clear : Color(hex: "4A4840"), lineWidth: 1)
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
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(hex: "D2B96A"))
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
//       .font(.system(size: 11, design: .monospaced))
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
    @Binding var photos: [Data]
    /// Show per-photo delete (xmark) buttons + the trailing "+ Add" tile.
    var isEditable: Bool = true
    /// Allow drag-to-reorder.
    var allowsReorder: Bool = true
    /// Tap-target for the "+ Add" tile. If nil and isEditable is true, no add tile shows.
    var onAdd: (() -> Void)? = nil
    /// Tap on a photo tile body → opens the full-screen viewer with this index.
    /// When omitted, the tile body is non-tappable (delete + drag still work).
    var onTap: ((Int) -> Void)? = nil
    var thumbnailSize: CGFloat = 100

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(photos.enumerated()), id: \.offset) { idx, data in
                    if let uiImage = UIImage(data: data) {
                        photoTile(uiImage: uiImage, idx: idx)
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
    private func photoTile(uiImage: UIImage, idx: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // Image (and MAIN badge) — tappable to open the full-screen viewer
            // when onTap is provided. Wrapped in a Button so child gestures
            // (delete X) layered above can still intercept their own taps.
            Button {
                onTap?(idx)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipped()
                        .cornerRadius(8)
                    if idx == 0 && photos.count > 1 {
                        Text("MAIN")
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(1)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "D2B96A"))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                            .padding(5)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil)
            if isEditable {
                Button { photos.remove(at: idx) } label: {
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
                    .foregroundColor(Color(hex: "D2B96A"))
                Text("Add")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .background(Color(hex: "D2B96A").opacity(0.08))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D2B96A").opacity(0.3), lineWidth: 1))
        }
    }

    private func movePhoto(from src: Int, to dst: Int) {
        guard src != dst,
              photos.indices.contains(src),
              photos.indices.contains(dst) else { return }
        let item = photos.remove(at: src)
        photos.insert(item, at: dst)
    }
}

// MARK: - Full-screen photo viewer + cover picker
//
// Used together with PhotoGalleryView's `onTap`. Tapping a thumbnail
// presents this viewer; if the tapped photo isn't already at index 0,
// the "Make main?" button moves it to position 0 (the cover).
// Persistence happens automatically through the parent's binding setter.

/// Identifiable wrapper so `.fullScreenCover(item:)` can present the viewer
/// keyed on the tapped tile's index.
struct PhotoViewerItem: Identifiable, Equatable {
    let id: Int
    let photo: Data
}

struct FullScreenPhotoViewer: View {
    let photo: Data
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
            if let img = UIImage(data: photo) {
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
                        onMakeMain()
                        dismiss()
                    } label: {
                        Text("Make main?")
                            .font(.system(size: 13, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(Color(hex: "D2B96A"))
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(hex: "D2B96A"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "D2B96A"))
                        Text("Main photo")
                            .font(.system(size: 13, design: .monospaced))
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
