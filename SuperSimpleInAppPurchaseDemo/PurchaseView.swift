//
//  PurchaseView.swift
//  SuperSimpleInAppPurchaseDemo
//

import OSLog
import StoreKit
import SwiftUI

/// A view for purchasing premium access to the app.
struct PurchaseView: View {

    @Environment(ProductStore.self) private var store: ProductStore

    private let logger = Logger(subsystem: "lorin.vanriel.SuperSimpleInAppPurchaseDemo", category: "PurchaseView")

    var body: some View {
        VStack(spacing: 40) {
            ProductView(id: ProductStore.fullAccessProductId)
                .productViewStyle(.compact)
                .padding()
                .onInAppPurchaseCompletion { product, result in
                    if case .success(let purchaseResult) = result {
                        await store.didCompletePurchase(product, purchaseResult: purchaseResult)
                    } else {
                        logger.warning("There was a problem completing the purchase.")
                    }
                }

            Text(verbatim: "Thank you for purchasing premium access!")
                .opacity(store.premiumAccessUnlocked ? 1 : 0)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PurchaseView()
        .environment(ProductStore())
}
