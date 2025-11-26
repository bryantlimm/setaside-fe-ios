//
//  DetailsView.swift
//  SetAside
//
//  Created by Rukiye Verep on 25.11.25.
//

import SwiftUI

struct DetailsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title and Price
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fresh Cabbage")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("$5.00/kg")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text("Fresh, organic cabbage harvested locally. Perfect for salads, soups, and various dishes. Rich in vitamins and nutrients, this cabbage is crisp and flavorful.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                // Additional details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Details")
                        .font(.headline)
                    
                    DetailRow(title: "Category:", value: "Vegetables")
                    DetailRow(title: "Weight:", value: "Approx. 1kg each")
                    DetailRow(title: "Origin:", value: "Local Farm")
                    DetailRow(title: "Storage:", value: "Keep refrigerated")
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    DetailsView()
}
