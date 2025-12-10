//
//  RegistrationView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack {
            // Yuqori qism
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Text("Fill your information below or register with your social account.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // --- Kirish maydonlari ---
            
            // Ism maydoni
            VStack(alignment: .leading, spacing: 5) {
                Text("Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Ex. John Doe", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Email maydoni
            VStack(alignment: .leading, spacing: 5) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("example@gmail.com", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding([.horizontal, .top])
            
            // Parol maydoni
            VStack(alignment: .leading, spacing: 5) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if isPasswordVisible {
                        TextField("**********", text: $password)
                    } else {
                        SecureField("**********", text: $password)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding([.horizontal, .top])
            
            // --- Shartlarga rozilik ---
            HStack {
                Toggle("", isOn: $agreedToTerms)
                    .labelsHidden()
                    .toggleStyle(CheckboxToggleStyle()) // Pastdagi yordamchi uslub (Style)
                
                Text("Agree with")
                
                Button("Terms & Condition") {
                    // Shartlar va qoidalar sahifasiga o'tish
                }
                .foregroundColor(Color(red: 0.38, green: 0.22, blue: 0.82))
                .fontWeight(.medium)
                
                Spacer()
            }
            .padding([.horizontal, .top])
            
            // --- Sign Up tugmasi ---
            Button("Sign Up") {
                signUp()
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.38, green: 0.22, blue: 0.82)) // Rasmga o'xshash binafsha rang
            .cornerRadius(15)
            .padding([.horizontal, .top], 30)
            
            // --- Ijtimoiy tarmoqlar orqali kirish ---
            Text("Or sign up with")
                .foregroundColor(.gray)
                .padding(.vertical, 20)
            
            HStack(spacing: 30) {
                SocialSignInButton(imageName: "applelogo")
                SocialSignInButton(imageName: "google")
                SocialSignInButton(imageName: "facebook")
            }
            
            // --- Hisobingiz bormi? ---
            Spacer()
            
            HStack {
                Text("Already have an account?")
                Button("Sign In") {
                    dismiss()
                }
                .foregroundColor(Color(red: 0.38, green: 0.22, blue: 0.82))
                .fontWeight(.medium)
            }
            .padding(.bottom, 20)
            
            // Pastki chiziqni imitatsiya qilish
            Rectangle()
                .frame(width: 134, height: 5)
                .cornerRadius(5)
                .foregroundColor(.black)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 10)
    }
}

// Checkbox uslubini yaratish uchun yordamchi struct
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? Color(red: 0.38, green: 0.22, blue: 0.82) : .gray)
                .font(.title2)
        }
    }
}

private extension RegistrationView {
    func signUp(){
        Task{await authManager.signUp(email: email, password: password, username: username)}
    }
}


#Preview {
    RegistrationView()
        .environment(AuthManager())
}
