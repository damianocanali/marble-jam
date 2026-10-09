import StoreKit

/// In-app purchases (StoreKit 2): the skin packs, what has been bought, buying and restoring.
@MainActor
final class Store: ObservableObject {
    /// Start of every product id. Must match the app's bundle id prefix used in App Store Connect and Products.storekit.
    nonisolated static let productPrefix = "com.example.marblejam"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchased: Set<String> = []
    @Published private(set) var failed: String?
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in                                  // purchases approved later (Ask to Buy) or on another device
            for await result in Transaction.updates {
                if case let .verified(t) = result { await t.finish(); await self?.refreshPurchases() }
            }
        }
    }

    deinit { updates?.cancel() }

    func load() async {
        do {
            let ids = Skins.packs.map(\.productID)
            products = try await Product.products(for: ids).sorted { ids.firstIndex(of: $0.id)! < ids.firstIndex(of: $1.id)! }
            failed = nil
        } catch { failed = "The store isn't available right now." }
        await refreshPurchases()
    }

    func refreshPurchases() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case let .verified(t) = result, t.revocationDate == nil { owned.insert(t.productID) }
        }
        purchased = owned
    }

    func buy(_ product: Product) async throws {
        switch try await product.purchase() {
        case let .success(.verified(t)): await t.finish(); purchased.insert(t.productID)
        case .success(.unverified): failed = "That purchase couldn't be verified."
        case .pending: failed = "Waiting for a grown-up to approve the purchase."
        case .userCancelled: break
        @unknown default: break
        }
    }

    /// "Restore Purchases": ask the App Store for everything this Apple ID has bought.
    func restore() async {
        try? await AppStore.sync()
        await refreshPurchases()
    }
}

/// "Ask a grown-up": a multiplication written in words, answered in digits, before any purchase.
enum ParentalGate {
    struct Question: Equatable { let text: String; let answer: Int }
    private static let words = ["six", "seven", "eight", "nine"]

    static func question(seed: Int = Int.random(in: 0..<10_000)) -> Question {
        let a = 6 + seed % 4, b = 6 + (seed / 4) % 4
        return Question(text: "What is \(words[a - 6]) times \(words[b - 6])?", answer: a * b)
    }

    static func check(_ input: String, against q: Question) -> Bool { Int(input.trimmingCharacters(in: .whitespaces)) == q.answer }
}
