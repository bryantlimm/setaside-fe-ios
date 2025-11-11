//
//  ProductListingPage.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct ProductListingPage: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HeaderView(username: "John Doe")
                    
                    VStack(alignment: .leading, spacing: 24) {
                        SearchBar()
                        CategoryGrid()
                        ProductGrid()
                            .padding(.bottom, 100)
                    }
                    .padding(.horizontal)
                }
                
            }
//            BottomNavBar()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ProductListingPage()
}
