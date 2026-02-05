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
    @State private var showAuthError = false
    @State private var showSocialInfo = false

    private var isValidForm: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
            && agreedToTerms
    }
    
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
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
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
            Button(authManager.isLoading ? "Creating..." : "Sign Up") {
                signUp()
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isValidForm
                    ? Color(red: 0.38, green: 0.22, blue: 0.82)
                    : Color.gray
            )
            .cornerRadius(15)
            .disabled(!isValidForm || authManager.isLoading)
            .padding([.horizontal, .top], 30)
            
            // --- Ijtimoiy tarmoqlar orqali kirish ---
            Text("Or sign up with")
                .foregroundColor(.gray)
                .padding(.vertical, 20)
            
            HStack(spacing: 30) {
                Button {
                    showSocialInfo = true
                } label: {
                    SocialSignInButton(imageName: "applelogo")
                }
                .buttonStyle(.plain)

                Button {
                    showSocialInfo = true
                } label: {
                    SocialSignInButton(imageName: "google")
                }
                .buttonStyle(.plain)

                Button {
                    showSocialInfo = true
                } label: {
                    SocialSignInButton(imageName: "facebook")
                }
                .buttonStyle(.plain)
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
        .onChange(of: authManager.authError) { _, newValue in
            showAuthError = newValue != nil
        }
        .alert("Sign Up Error", isPresented: $showAuthError) {
            Button("OK") {
                authManager.clearAuthError()
            }
        } message: {
            Text(authManager.authError ?? "Unknown error")
        }
        .alert("Info", isPresented: $showSocialInfo) {
            Button("OK") {}
        } message: {
            Text("Social sign up hozircha yoqilmagan.")
        }
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedUsername.isEmpty,
            !trimmedEmail.isEmpty,
            password.count >= 6,
            agreedToTerms,
            !authManager.isLoading
        else { return }

        Task {
            await authManager.signUp(
                email: trimmedEmail,
                password: password,
                username: trimmedUsername
            )
        }
    }
}


#Preview {
    RegistrationView()
        .environment(AuthManager())
}
