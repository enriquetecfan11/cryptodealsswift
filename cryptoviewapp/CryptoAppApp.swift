//
//  cryptoviewappApp.swift
//  cryptoviewapp
//
//  Created by Kike Rodriguez Vela on 9/7/25.
//

import SwiftUI

@main
struct CryptoAppApp: App {
    @StateObject private var cryptoViewModel = CryptoViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(cryptoViewModel)
        }
    }
}

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemGray6 // Color minimalista
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    var body: some View {
        TabView {
            NavigationView { HomeView() }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Inicio")
                }
            NavigationView { CryptoListView() }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Lista")
                }
            NavigationView { PortfolioView() }
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Portafolio")
                }
        }
        .font(adaptiveTabFont)
    }
    
    private var adaptiveTabFont: Font {
        DeviceInfo.isIPad ? .footnote : .caption2
    }
}
