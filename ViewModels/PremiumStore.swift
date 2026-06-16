import StoreKit
import SwiftUI
import Combine   // @Published lives in Combine; required explicitly under the project's MemberImportVisibility feature

/// StoreKit 2 manager for the one-time "Stesura Premium" unlock.
///
/// Free tier caps each library type (recipes, flour blends, processes,
/// preferments) at `RecipeStore.freeItemLimit` (2 each, incl. seeded
/// items). A single non-consumable purchase removes the caps forever and
/// restores across the user's devices.
///
/// Source of truth for entitlement is StoreKit's currentEntitlements —
/// we never persist a "paid" flag ourselves (that would be trivially
/// spoofable and could drift). `isPremium` is recomputed from StoreKit
/// on launch, after a purchase, and on any external transaction update.
///
/// Note: no explicit @MainActor — the project builds with
/// -default-isolation=MainActor, so this class is already main-actor
/// isolated like RecipeStore. An explicit @MainActor here clashes with
/// InferIsolatedConformances and breaks the ObservableObject conformance.
final class PremiumStore: ObservableObject {
    /// Must match the non-consumable product ID created in App Store
    /// Connect.
    static let productID = "com.stesura.app.premium"

    /// Effective entitlement the app gates on. In release this equals the
    /// real StoreKit purchase; in DEBUG it's OR'd with `debugUnlock`.
    @Published private(set) var isPremium = false
    /// The real verified StoreKit entitlement (independent of the debug
    /// override).
    private var purchased = false
    @Published private(set) var product: Product?
    @Published var lastError: String?
    /// True while a purchase/restore network call is in flight (drives
    /// a spinner + disables buttons in the paywall).
    @Published var working = false

    #if DEBUG
    /// DEBUG-only dev override: when on, the app behaves as Premium without
    /// a purchase, so you can use the full app while developing. Toggle it
    /// off (Settings → Developer) to exercise the free-tier caps/paywall.
    /// Persisted, defaults on. Compiled out of release builds entirely.
    @Published var debugUnlock: Bool =
        (UserDefaults.standard.object(forKey: "debug_force_premium") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(debugUnlock, forKey: "debug_force_premium")
            recomputePremium()
        }
    }
    #endif

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        recomputePremium()   // reflect the debug override immediately on launch
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    /// Recompute the effective `isPremium` from the real purchase plus
    /// (in DEBUG) the dev override.
    private func recomputePremium() {
        #if DEBUG
        isPremium = purchased || debugUnlock
        #else
        isPremium = purchased
        #endif
    }

    // No deinit: this store lives for the app's lifetime (@StateObject),
    // so the transactions listener never needs cancelling — and a deinit
    // touching a main-actor-isolated property trips strict-isolation.

    /// Localized price string from the store, with a sensible fallback
    /// before the product has loaded.
    var displayPrice: String { product?.displayPrice ?? "$1.99" }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            // Leave product nil; the paywall shows the fallback price and
            // can retry on next appearance.
        }
    }

    /// Recompute the real purchase state from StoreKit's verified current
    /// entitlements, then fold in the debug override.
    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
                break
            }
        }
        purchased = owned
        recomputePremium()
    }

    /// Buy the unlock. No-op feedback on cancel; sets `isPremium` on a
    /// verified success.
    func purchase() async {
        working = true
        defer { working = false }
        if product == nil { await loadProduct() }
        guard let product else {
            lastError = "Couldn't reach the App Store. Try again in a moment."
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Restore Purchases — required by App Review. Syncs with the App
    /// Store then re-checks entitlements.
    func restore() async {
        working = true
        defer { working = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isPremium {
                lastError = "No previous purchase found on this Apple ID."
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Background listener for transactions that arrive outside an
    /// in-app purchase (e.g. a restore on another device, Ask-to-Buy
    /// approval, refunds).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }
}

// MARK: - Paywall

/// Shown when a free user hits the recipe cap, and from Settings.
struct PaywallView: View {
    @EnvironmentObject var premium: PremiumStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer(minLength: 8)

                Text("Stesura Premium")
                    .font(.fraunces(.semibold, size: 30))
                    .foregroundColor(.stesuraInk)

                Text("The free version keeps 2 each of recipes, flour blends, processes, and preferments. Unlock to save as many as you like — and import recipes friends share with you.")
                    .font(.jakarta(.regular, size: 15))
                    .foregroundColor(.stesuraInkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    benefit("Unlimited recipes, blends, processes & preferments")
                    benefit("Import shared recipes anytime")
                    benefit("One-time purchase — yours forever")
                }
                .padding(.vertical, 4)

                Spacer()

                Button {
                    Task { await premium.purchase(); if premium.isPremium { dismiss() } }
                } label: {
                    HStack {
                        if premium.working { ProgressView().tint(.white) }
                        Text(premium.working ? "Working…" : "Unlock for \(premium.displayPrice)")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StesuraButtonStyle(filled: true))
                .disabled(premium.working)
                .padding(.horizontal, 24)

                Button("Restore Purchase") {
                    Task { await premium.restore(); if premium.isPremium { dismiss() } }
                }
                .font(.jakarta(.regular, size: 14))
                .foregroundColor(.ruleBlue)
                .disabled(premium.working)

                if let err = premium.lastError {
                    Text(err)
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.marginRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 8)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.paperWhite.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not now") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: premium.isPremium) { _, now in
                if now { dismiss() }
            }
        }
        .preferredColorScheme(.light)
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.ruleBlue)
            Text(text).font(.jakarta(.regular, size: 15)).foregroundColor(.stesuraInk)
        }
    }
}
