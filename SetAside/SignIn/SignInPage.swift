//
//  SignInPage.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct SignInPage: View {
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
                    Text("Welcome Back!")
                        .font(.system(size: 40, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    Text("We’re glad to see you again.")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    SignInContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.white)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    SignInPage()
}
