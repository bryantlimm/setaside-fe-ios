//
//  DetailRow.swift
//  SetAside
//
//  Created by Rukiye Verep on 25.11.25.
//

import SwiftUI

// Reusable Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
