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

    override func setUpWithError() throws {
        store = ProductStore()

        session = try SKTestSession(configurationFileNamed: "SuperSimpleInAppPurchaseConfig")
        session.disableDialogs = true
        session.clearTransactions()
        session.resetToDefaultState()
    }

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
}
