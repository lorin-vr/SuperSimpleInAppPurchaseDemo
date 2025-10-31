//
//  SuperSimpleInAppPurchaseDemoTests.swift
//  SuperSimpleInAppPurchaseDemoTests
//

import StoreKitTest
import XCTest
@testable import SuperSimpleInAppPurchaseDemo

@MainActor
final class ProductStoreTests: XCTestCase {

    private var store: ProductStore!
    private var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        store = ProductStore()

        session = try SKTestSession(configurationFileNamed: "SuperSimpleInAppPurchaseConfig")
        session.disableDialogs = true
        session.clearTransactions()
        session.resetToDefaultState()
    }

    // MARK: - New purchases

    func testSuccessfulVerifiedPurchase() async throws {
        XCTAssertFalse(store.premiumAccessUnlocked)

        guard let product = try await Product.products(for: [ProductStore.fullAccessProductId]).first else {
            return XCTFail("Cannot find premium access product")
        }

        let transaction = try await session.buyProduct(identifier: ProductStore.fullAccessProductId)
        await store.didCompletePurchase(product, purchaseResult: .success(.verified(transaction)))
        
        XCTAssertTrue(store.premiumAccessUnlocked)
    }

    func testUnverifiedPurchase() async throws {
        XCTAssertFalse(store.premiumAccessUnlocked)

        guard let product = try await Product.products(for: [ProductStore.fullAccessProductId]).first else {
            return XCTFail("Cannot find premium access product")
        }

        let transaction = try await session.buyProduct(identifier: ProductStore.fullAccessProductId)
        await store.didCompletePurchase(product, purchaseResult: .success(.unverified(transaction, .invalidSignature)))

        XCTAssertFalse(store.premiumAccessUnlocked)
    }

    func testCancelledPurchase() async throws {
        XCTAssertFalse(store.premiumAccessUnlocked)

        guard let product = try await Product.products(for: [ProductStore.fullAccessProductId]).first else {
            return XCTFail("Cannot find premium access product")
        }

        await store.didCompletePurchase(product, purchaseResult: .userCancelled)

        XCTAssertFalse(store.premiumAccessUnlocked)
    }

// `SKTestSession.askToBuyEnabled = true` is not working on Xcode 15.2
// Filed feedback FB13554125
// See also https://developer.apple.com/forums/thread/740359
//
    func testAskToBuyPurchase() async throws {
        // Setting askToBuyEnabled seems to have no effect
        session.askToBuyEnabled = true

        // Check there are no current transactions, and the feature has not yet been unlocked
        XCTAssertEqual(session.allTransactions().count, 0)
        XCTAssertFalse(store.premiumAccessUnlocked)

        guard let product = try await Product.products(for: [ProductStore.fullAccessProductId]).first else {
            return XCTFail("Cannot find premium access product")
        }

        // Try to purchase the product
        let transaction = try await session.buyProduct(identifier: ProductStore.fullAccessProductId)

        // Complete the purchase on the store, with result 'pending'
        await store.didCompletePurchase(product, purchaseResult: .pending)

        // Check that the the feature is still locked, because ask to buy confirmation is pending
        XCTAssertFalse(store.premiumAccessUnlocked)

        // Check that there is now a StoreKit transaction
        XCTAssertEqual(session.allTransactions().count, 1)

        XCTExpectFailure("There may be a StoreKitTest bug with askToBuy, so the rest of this test does not work as expected.")

        // The transaction state should be `deferred`, but instead it is `purchased`
        XCTAssertEqual(session.allTransactions()[0].state, .deferred)

        // The transaction should be pending ask to buy confirmation, but this call fails
        XCTAssertTrue(session.allTransactions()[0].pendingAskToBuyConfirmation)

        // Approve the ask to buy transaction
        try session.approveAskToBuyTransaction(identifier: UInt(transaction.id))

        // The feature should now be unlocked
        XCTAssertTrue(store.premiumAccessUnlocked)
    }

    // MARK: - Previous purchases

    func testCurrentEntitlementsContainsPreviousPurchase() async throws {
        let oneMonthAgo = TimeInterval(-24 * 60 * 60 * 30)

        // Set store to nil so that it is not listening for transactions
        store = nil

        // Purchase a product one month in the past
        try await session.buyProduct(identifier: ProductStore.fullAccessProductId, options: [.purchaseDate(.now.addingTimeInterval(oneMonthAgo))])

        // Confirm that the purchase was successful
        XCTAssertEqual(session.allTransactions().count, 1)
        XCTAssertTrue(session.allTransactions()[0].state == .purchased)

        // Initialise a new store. The initialiser should look for any current entitlements (previous successful purchases) to update the product status.
        store = ProductStore()

        // Set up an expectation that the feature will be unlocked. This would mean that the store found a current entitlement for the product.
        let featureIsUnlockedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ -> Bool in
                self.store.premiumAccessUnlocked == true
            }),
            object: store)

        // Wait for the store to read the entitlement and unlock the feature
        await fulfillment(of: [featureIsUnlockedExpectation], timeout: 5.0)

        // Extra check that the feature is indeed unlocked
        // (Shouldn't be necessary, since the expectation is checking the same thing)
        XCTAssertTrue(store.premiumAccessUnlocked)
    }
}
