import SwiftUI
import PhotosUI

// MARK: - Font ledger

extension Font {
    /// Fraunces — display / headline serif
    /// PostScript name: Fraunces72pt-Regular
    static func fraunces(_ size: CGFloat) -> Font {
        .custom("Fraunces72pt-Regular", size: size)
    }

    /// Plus Jakarta Sans — UI / body sans-serif
    /// Weights: .light / .regular / .medium / .semibold
    static func jakarta(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .light:    name = "PlusJakartaSans-Light"
        case .medium:   name = "PlusJakartaSans-Medium"
        case .semibold: name = "PlusJakartaSans-SemiBold"
        default:        name = "PlusJakartaSans-Regular"
        }
        return .custom(name, size: size)
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

struct ImpastoButtonStyle: ButtonStyle {
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
