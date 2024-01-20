//
//  SuperSimpleInAppPurchaseDemoApp.swift
//  SuperSimpleInAppPurchaseDemo
//

import SwiftUI

@main
struct SuperSimpleInAppPurchaseDemoApp: App {
    
    // Make it `@State` so that SwiftUI will manage the lifetime of the store
    @State private var store = ProductStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(store)
        }
    }
}
