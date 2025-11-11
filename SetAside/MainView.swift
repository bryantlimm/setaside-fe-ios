//
//  MainView.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    ProductListingPage()
                case 1:
                    ProductListingPage()
//                    StoreLocationPage()
                case 2:
                    ProductListingPage()
//                    ReceiptPage()
                case 3:
                    ProductListingPage()
//                    AccountPage()
                default:
                    ProductListingPage()
                }
            }
            .ignoresSafeArea(.all, edges: .all)

            BottomNavBar(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.all, edges: .all)
    }
}

#Preview {
    MainView()
}
