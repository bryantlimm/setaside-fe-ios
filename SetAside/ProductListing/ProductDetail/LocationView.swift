//
//  LocationView.swift
//  SetAside
//
//  Created by Rukiye Verep on 25.11.25.
//

import SwiftUI

struct LocationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Product Location")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Mock map placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Map View")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Store Information")
                        .font(.headline)
                    
                    DetailRow(title: "Store:", value: "Fresh Market")
                    DetailRow(title: "Address:", value: "123 Green Street, City")
                    DetailRow(title: "Distance:", value: "2.3 km away")
                    DetailRow(title: "Hours:", value: "8:00 AM - 9:00 PM")
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    LocationView()
}
