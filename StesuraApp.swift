import SwiftUI
import UIKit

@main
struct StesuraApp: App {
    @StateObject private var store = RecipeStore()
    @StateObject private var sessionManager = SessionManager()

    init() {
        // Apply global UIKit appearance overrides — these set the default
        // font for surfaces SwiftUI doesn't expose via .font() modifiers:
        // navigation titles ("Library", "Settings", recipe names), nav bar
        // buttons (Cancel / Done / Edit / etc.), and Picker text. SwiftUI
        // Section headers / List section text use these too on iOS 16+.
        //
        // Falls back to system fonts gracefully if a custom font is missing.

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        if let inlineFont = UIFont(name: "Fraunces-SemiBold", size: 17) {
            navAppearance.titleTextAttributes[.font] = inlineFont
        }
        if let largeFont = UIFont(name: "Fraunces-SemiBold", size: 34) {
            navAppearance.largeTitleTextAttributes[.font] = largeFont
        }
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance

        // Row separators throughout the app in rule-blue (#7FA2BD) to
        // match the Mead notebook theme. UITableView appearance covers
        // SwiftUI Form rows (Form is still UITableView-backed on iOS 26);
        // List rows use UICollectionView and need .listRowSeparatorTint
        // applied per-Section in the view code.
        UITableView.appearance().separatorColor = UIColor(
            red: 0x7F/255.0, green: 0xA2/255.0, blue: 0xBD/255.0, alpha: 1
        )

        // Bar button text (Cancel / Done / Edit / etc.) in Jakarta.
        if let barFont = UIFont(name: "PlusJakartaSans-Regular_Medium", size: 16) {
            UIBarButtonItem.appearance().setTitleTextAttributes(
                [.font: barFont], for: .normal
            )
            UIBarButtonItem.appearance().setTitleTextAttributes(
                [.font: barFont], for: .highlighted
            )
        }
    }

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
                }
        }
    }
}
