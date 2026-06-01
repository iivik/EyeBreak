import StoreKit

// StoreKit 2 purchase manager.
// Product ID must match what's registered in App Store Connect.
class PurchaseManager {
    static let shared = PurchaseManager()
    static let productID = "com.vikasanand.eyebreak.unlock"

    // Read on main thread only. Written via MainActor.run from async tasks.
    private(set) var isPurchased = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await refreshStatus() }
    }

    // MARK: - Status

    func refreshStatus() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.productID {
                found = true
            }
        }
        let result = found
        await MainActor.run { self.isPurchased = result }
    }

    // MARK: - Purchase

    func purchase() async throws {
        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else { return }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return }
            await tx.finish()
            await MainActor.run { self.isPurchased = true }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restore() async throws {
        try await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      case .verified(let tx) = result,
                      tx.productID == PurchaseManager.productID else { continue }
                await tx.finish()
                await MainActor.run { self.isPurchased = true }
            }
        }
    }
}
