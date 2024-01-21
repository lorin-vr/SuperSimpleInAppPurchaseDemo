//
//  ProductStore.swift
//  SuperSimpleInAppPurchaseDemo
//

import StoreKit

/// Class to manage unlocking features in response to in-app purchases
@Observable final class ProductStore {

    enum StoreKitError: Error {
        case failedVerification
    }

    // Must match the Product ID set up in App Store Connect (for production) or StoreKit configuration file (for local testing)
    static let fullAccessProductId = "SuperSimpleInAppPurchaseDemo.nonconsumable.premiumfeature"

    // This simple app has only one product: premium access
    @MainActor
    private(set) var premiumAccessUnlocked: Bool = false

    private var updateListenerTask: Task<Void, Error>? = nil

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            // Unlock products that the user has purchased.
            await unlockPreviouslyPurchasedFeatures()
        }
    }

    deinit {
        // Transaction listener is active for the lifetime of this store
        updateListenerTask?.cancel()
    }

    /// Take an action as the result of a purchase.
    /// If successful, unlock the product that was purchased. If the purchase was unsuccessful or could not be verified, do nothing.
    ///
    /// - Parameters:
    ///   - product: The product being purchased
    ///   - purchaseResult: Indicates the status of the purchase, e.g. successful, pending, or cancelled
    func didCompletePurchase(_ product: Product, purchaseResult: Product.PurchaseResult) async {
        do {
            switch purchaseResult {
            case let .success(.verified(transaction)):
                // Successful, verified purchase
                // Unlock the purchased product
                await unlockFeature(for: transaction)

                // Mark the transaction as finished, indicating that we have dealt with it by unlocking the feature.
                await transaction.finish()
            case .success(.unverified):
                // Successful purchase but JWS couldn't be verified.
                throw StoreKitError.failedVerification
            case .pending:
                // Transaction waiting for SCA (Strong Customer Authentication) or Ask to Buy.
                // No action necessary here. We'll listen to `Transaction.updates` to know if the purchase completes.
                break
            case .userCancelled:
                // User cancelled the transaction. No action necessary.
                break
            @unknown default:
                break
            }
        } catch {
            // Could perhaps show an error in this case, but it's not clear what action a user should take.
            print("StoreKit transaction could not be verified.")
        }
    }

    // MARK: - Private methods

    /// Listen for transactions that may have
    ///  1) happened on a another device
    ///  2) Completed SCA
    ///  3) Completed Ask to Buy
    ///
    ///  Theoretically, new updates could appear at any time, but Apple has indicated that updates are most likely to appear once, shortly after app startup. So this method should be called early.
    ///
    ///  Apple's docs demonstrate that we can run this task with `background` priority:
    ///  https://developer.apple.com/documentation/storekit/transaction/3851206-updates
    ///
    /// - Returns: A task that can be cancelled when we no longer want to listen for transactions
    private func listenForTransactions() -> Task<Void, Error> {
        Task(priority: .background) {
            // Loop through the `Transaction.updates` stream.
            for await result in Transaction.updates {
                do {
                    switch result {
                    case .verified(let transaction):
                        // Successful, verified purchase
                        // Unlock the purchased product
                        await self.unlockFeature(for: transaction)

                        // Mark the transaction as finished, indicating that we have dealt with it by unlocking the feature.
                        await transaction.finish()
                    case .unverified:
                        // Successful purchase but JWS couldn't be verified.
                        throw StoreKitError.failedVerification
                    }
                } catch {
                    // Nothing we can really do about unverified transactions.
                    print("StoreKit transaction could not be verified.")
                }
            }
        }
    }

    /// Check the user's transaction history using `Transaction.currentEntitlements`.
    /// For any verified purchases, unlock the corresponding product. For any unverified purchases, do nothing.
    /// Because `Transaction.currentEntitlements` uses local caching if the network is unavailable, this method works both online and offline.
    @MainActor
    private func unlockPreviouslyPurchasedFeatures() async {
        // Loop through the user's transaction history, looking for verified, purchased products
        for await result in Transaction.currentEntitlements {
            do {
                switch result {
                case .verified(let transaction):
                    // Successful, verified purchase
                    // Unlock the purchased product
                    await unlockFeature(for: transaction)
                    // No need to call `transaction.finish()`, because this is a historical transaction.
                case .unverified:
                    // Successful purchase but JWS couldn't be verified.
                    throw StoreKitError.failedVerification
                }
            } catch {
                // Nothing we can really do about unverified transactions.
                print("StoreKit transaction could not be verified.")
            }
        }
    }

    /// Unlock a feature corresponding to a product that has been purchased.
    /// In our case we only have one product, so it's very simple. If the transaction's `productType` and `productID` match our product, we mark the feature as unlocked.
    ///
    /// Unlocking the feature will trigger a UI update, so this function must run on the `MainActor`.
    ///
    /// - Parameters:
    ///   - transaction: A transaction for the product intended to be unlocked
    @MainActor
    private func unlockFeature(for transaction: Transaction) async {
        if transaction.productType == .nonConsumable && transaction.productID == Self.fullAccessProductId {
            premiumAccessUnlocked = true
        }
    }
}
