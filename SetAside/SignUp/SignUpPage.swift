//
//  SignUpPage.swift
//  SetAsideApp
//
//  Created by Bryant Aryadi on 24/09/25.
//

import SwiftUI

struct SignUpPage: View {
    var body: some View {
        ZStack {
            Image("AuthBG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Image("SetAsideLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 16) {
                    Text("We Set them aside for you!")
                        .font(.system(size: 40, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    Text("Shopping made easy with SetAside")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    SignUpContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.white)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    SignUpPage()
}

