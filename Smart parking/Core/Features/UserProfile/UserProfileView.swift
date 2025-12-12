//
//  UserProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 10/12/25.
//

import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    
    @State private var selectedItem
    :PhotosPickerItem?
    @State private var profileImage : Image?
    @State private var showPhotoPicker = false
    var body: some View {
        NavigationStack{
            List{
                Section{
                    HStack(spacing: 16){
                        Group {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(.circle)
                            }
                            
                            else if let profileImageURL = userManager.currentUser?.profileImageURL {
                                AsyncImage(url: URL(string: profileImageURL)!){ image in
                                    image
                                        .resizable()
                                        .clipShape(.circle)
                                } placeholder :{
                                    ProgressView()
                                }
                                
                            }
                            else{
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.tertiary)
                            }
                            
                        }
                        .frame(width: 72, height: 72)
                        .onTapGesture {
                            showPhotoPicker.toggle()
                        }
                        
                        VStack(alignment: .leading, spacing:6){
                            Text(userManager.currentUser?.username ?? "Loading")
                            Text(userManager.currentUser?.email ?? "Loading")
                        }
                    }
                }
                Section{
                    Button("Sign out"){
                        Task{
                            await authManager.signOut()
                        }
                    }
                    .foregroundStyle(Color.red)
                  
                    
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem)
        }
        
        .task {
            await userManager.fetchCorrentUser()
        }
        .task(id: selectedItem) {
            await onImageSelection()
        }
    }
}

private extension UserProfileView {
    func onImageSelection() async {
        guard let selectedItem, let user = userManager.currentUser else { return}
        
        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: data) else{return}
            
            profileImage = Image(uiImage: uiImage)
            
            let userProfileImageURL = try await SupabaseStorageManager().uploadProfilePhoto(for: user, imageData: data)
            await userManager.updateProfileImageURL(userProfileImageURL)
        }
        catch{
            print("DEBUG: error loading data ) \(error.localizedDescription)")
        }
    }
}

#Preview {
    UserProfileView()
}
