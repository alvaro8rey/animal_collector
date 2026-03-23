import StoreKit
import Foundation

/// Manages all StoreKit 2 operations: loading products, purchasing, restoring,
/// and listening for subscription changes from the App Store.
@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product ID
    // ⚠️ Cambia este valor para que coincida exactamente con el Product ID
    // que crees en App Store Connect (debe incluir tu Bundle ID real).
    static let monthlyProductID = "com.animalcollector.app.premium.monthly"

    // MARK: - Published state

    @Published var product: Product?
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var purchaseError: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init / deinit

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProduct()
            await refreshPurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load product from App Store

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductID])
            product = products.first
        } catch {
            print("StoreKit: no se pudo cargar el producto: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product else { throw StoreError.productNotFound }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPremium = true
        case .userCancelled:
            break  // el usuario canceló, no hay error
        case .pending:
            break  // requiere aprobación de un familiar (Family Sharing), se resolverá vía Transaction.updates
        @unknown default:
            break
        }
    }

    // MARK: - Restore purchases

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Sincroniza el recibo con el servidor de Apple y actualiza las transacciones locales
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            print("StoreKit: restore fallido: \(error)")
        }
    }

    // MARK: - Refresh purchase status

    /// Comprueba los derechos actuales del usuario contra el servidor de Apple.
    func refreshPurchaseStatus() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.monthlyProductID,
               transaction.revocationDate == nil {
                hasPremium = true
            }
        }
        isPremium = hasPremium
    }

    // MARK: - Listen for external transaction updates

    /// Escucha renovaciones, cancelaciones y compras desde otros dispositivos.
    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    // Si la suscripción fue revocada (cancelada/reembolsada) revocationDate != nil
                    isPremium = transaction.revocationDate == nil
                } catch {
                    print("StoreKit: verificación de transacción fallida: \(error)")
                }
            }
        }
    }

    // MARK: - Verification helper

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    // MARK: - Errors

    enum StoreError: LocalizedError {
        case productNotFound
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Producto no disponible. Comprueba tu conexión e inténtalo de nuevo."
            case .failedVerification:
                return "No se pudo verificar la compra con Apple. Inténtalo de nuevo."
            }
        }
    }
}
