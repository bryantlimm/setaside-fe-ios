//
//  SearchBar.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct SearchBar: View {
    @State private var searchText = ""

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)

                TextField("Search", text: $searchText)
                    .padding(12)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)

            
            Button(action: {}) {
                Image("filter")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(Color(red: 0.38, green: 0.51, blue: 0.39))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    SearchBar()
}
