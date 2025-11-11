import SwiftUI

struct SignUpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Create an account")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Welcome to SetAside")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            // Input fields
            VStack(spacing: 16) {
                Columns(label: "Email", iconName: "EmailIcon")
                Columns(label: "Password", iconName: "PasswordIcon")
            }
            
            // Button
            CustomButton(title: "Sign Up")
//            Button("Sign Up") {
//                print("Sign Up tapped!")
//            }
//            .padding()
//            .frame(maxWidth: .infinity)
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
            
            HStack(spacing: 4) {
                Text("Already have an account? Sign in ")
                    .foregroundColor(.gray)
                
                NavigationLink(destination: SignInPage()) {
                    Text("here")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)

        }
        .padding()
    }
}

#Preview {
    SignUpContent()
}
