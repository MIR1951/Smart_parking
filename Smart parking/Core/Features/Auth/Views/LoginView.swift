//
//  LoginView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email: String = "example@gmail.com" // Joy egasi (Placeholder) sifatida ishlatilgan
    @State private var password: String = "12345678" // Joy egasi (Placeholder) sifatida ishlatilgan
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Yuqori qism
                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Text("Hi! Welcome back, you've been missed")
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
                
                // --- Kirish maydonlari ---
                
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
                .padding(.horizontal)
                
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
                    
                    // Parolni unutdingizmi? tugmasi
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Parolni tiklash amali
                        }
                        .foregroundColor(Color(red: 0.38, green: 0.22, blue: 0.82)) // Rasmga o'xshash binafsha rang
                        .font(.footnote)
                    }
                }
                .padding([.horizontal, .top])
                
                // --- Sign In tugmasi ---
                Button("Sign In") {
                    signIn()
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
                Text("Or sign in with")
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                
                HStack(spacing: 30) {
                    SocialSignInButton(imageName: "applelogo")
                    SocialSignInButton(imageName: "google") // 'google' va 'facebook' uchun maxsus rasm kerak
                    SocialSignInButton(imageName: "facebook")
                }
                
                // --- Hisobingiz yo'qmi? ---
                Spacer()
                NavigationLink{
                    RegistrationView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack {
                        Text("Don't have an account?")
                        Text("Sign Up")
                            .foregroundColor(Color(red: 0.38, green: 0.22, blue: 0.82))
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 20)
                }
                
                
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
}

// Ijtimoiy tarmoq tugmalari uchun yordamchi struct (rasmlar SF Symbols orqali shartli ravishda berilgan)
struct SocialSignInButton: View {
    var imageName: String
    
    var body: some View {
        // Haqiqiy ilovada Apple, Google, Facebook logotiplari alohida rasm resurslari sifatida yuklanadi.
        // Bu erda namuna sifatida SF Symbols ishlatilgan.
        if imageName == "applelogo" {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(15)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
        } else {
            // Google va Facebook logolari uchun joy egasi
            Text(imageName.prefix(1).uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 55, height: 55)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
}
private extension LoginView {
    func signIn(){
        Task{
            await authManager.signIn(email: email, password: password)
        }
    }
    
}


#Preview {
    LoginView()
        .environment(AuthManager())
}
