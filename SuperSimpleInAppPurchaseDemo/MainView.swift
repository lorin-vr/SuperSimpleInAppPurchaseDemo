//
//  MainView.swift
//  SuperSimpleInAppPurchaseDemo
//

import SwiftUI

/// The main view of the app. Shows either basic features or premium features, depending on whether premium access has been unlocked.
struct MainView: View {

    @Environment(ProductStore.self) private var store: ProductStore

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 40) {
                    Image(systemName: shouldShowPremiumFeature ? "figure.snowboarding" : "figure.walk")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                        .foregroundStyle(shouldShowPremiumFeature ? .purple : .gray)
                    Text(verbatim:
                        shouldShowPremiumFeature
                        ? "This is the premium version of the app"
                        : "This is the basic version of the app")
                        .font(.title)

                    Text(verbatim:
                        shouldShowPremiumFeature
                        ? "Thank you for upgrading to premium!"
                        : "Premium access has not been purchased.")
                    .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.vertical, 40)

                NavigationLink("Shop") {
                    PurchaseView()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Super Simple App")
        }
    }

    private var shouldShowPremiumFeature: Bool {
        store.premiumAccessUnlocked
    }
}

#Preview {
    MainView()
        .environment(ProductStore())
}
