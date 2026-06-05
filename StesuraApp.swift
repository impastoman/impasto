import SwiftUI

@main
struct StesuraApp: App {
    @StateObject private var store = RecipeStore()
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(sessionManager)
                .preferredColorScheme(.light)
                .onAppear {
                    // Install global tap-anywhere-to-dismiss-keyboard.
                    // Idempotent — safe to call repeatedly.
                    UIApplication.shared.installDismissKeyboardOnTap()

                    // TEMP — dump PostScript names of installed custom fonts
                    // so we can wire them up by their exact identifiers in
                    // StesuraStyle.swift. Remove this block once names are
                    // captured.
                    print("============ STESURA FONT DUMP ============")
                    let stesuraFamilies = ["Fraunces", "Plus Jakarta Sans", "PlusJakartaSans"]
                    for family in UIFont.familyNames.sorted()
                    where stesuraFamilies.contains(where: { family.localizedCaseInsensitiveContains($0) }) {
                        print("=== \(family) ===")
                        for name in UIFont.fontNames(forFamilyName: family) {
                            print("  \(name)")
                        }
                    }
                    print("===========================================")
                }
        }
    }
}
