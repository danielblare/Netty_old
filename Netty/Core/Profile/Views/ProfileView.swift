//
//  ProfileView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    
    // Presenting sheet to let user choose new avatar photo
    @State private var showPhotoImportSheet: Bool = false
    
    // Source of input photo
    @State private var photoInputSource: UIImagePickerController.SourceType = .camera
    
    // Shows dialog with options to choose new photo from library, take new photo, remove current avatar
    @State private var showProfilePhotoChangingConfirmationDialog: Bool = false
    
    // Current user record ID
    let userId: CKRecord.ID
    
    // Func passed from logInAndOutViewModel to let user log out
    let logOutFunc: () async -> ()
    
    // View Model
    @StateObject private var vm: ProfileViewModel
    
    
    init(userId: CKRecord.ID, logOutFunc: @escaping () async -> ()) {
        self.userId = userId
        self.logOutFunc = logOutFunc
        self._vm = .init(wrappedValue: ProfileViewModel(id: userId, logOutFunc: logOutFunc))
    }
        
    var body: some View {
        GeometryReader { proxy in

            NavigationView {
                
                ScrollView {
                    
                    // Image and user info
                    HStack {
                        
                        ProfileImage
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(.horizontal)
                            .onTapGesture {
                                showProfilePhotoChangingConfirmationDialog = true
                            }
                            .confirmationDialog("", isPresented: $showProfilePhotoChangingConfirmationDialog, titleVisibility: .hidden) {
                                getConfirmationActions()
                            }
                        
                        UserInfo
                            .padding(.vertical)
                            .frame(height: 100)
                        
                        Spacer(minLength: 0)
                        
                    }
                    .padding(.vertical)
                    
//                    LazyVGrid(columns: .init(repeating: GridItem(spacing: 1), count: 3), spacing: 1) {
//                        ForEach() { _ in
//                            Image(_)
//                                .resizable()
//                        }
//                    }
                    
                }
                .toolbar {
                    getToolbar()
                }
                .refreshable {
                    Task {
                        await vm.sync()
                    }
                }
                .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}, message: {
                    Text(vm.alertMessage)
                })
                .fullScreenCover(isPresented: $showPhotoImportSheet) {
                    ImagePicker(source: photoInputSource) { image in
                        vm.uploadImage(image, for: userId)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    // Creates toolbar for NavigationView
    @ToolbarContentBuilder private func getToolbar() -> some ToolbarContent {
        
        // Setting button
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                ProfileSettingsView(vm: vm)
            } label: {
                Image(systemName: "gearshape")
            }
        }
        
        // Title
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Profile")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
    
    // Profile avatar
    private var ProfileImage: some View {
        ZStack {
            if let image = vm.image { // image view
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if vm.isLoading { // loading view
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            } else { // no avatar view
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.3))
                    .overlay {
                        Image(systemName: "questionmark")
                            .foregroundColor(.secondary)
                    }
            }
        }
    }
    
    private var UserInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // User data
            if let firstName = vm.firstName,
               let lastName = vm.lastName,
               let nickname = vm.nickname {
                Text("\(firstName) \(lastName)")
                    .lineLimit(1)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(nickname)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else { // loading view
                LoadingAnimation()
                    .padding(.vertical)
            }
            
            
            Spacer(minLength: 0)
        }
    }
    
    // Creates confirmation dialog with options to select new avatar
    @ViewBuilder private func getConfirmationActions() -> some View {
        Button("Remove current photo") {
            vm.uploadImage(nil, for: userId)
        }
        
        Button("Choose from library") {
            photoInputSource = .photoLibrary
            showPhotoImportSheet = true
        }
        
        Button("Take photo") {
            photoInputSource = .camera
            showPhotoImportSheet = true
        }
        
        Button("Cancel", role: .cancel) {
            print("Cancel")
        }
    }
}









struct ProfileView_Previews: PreviewProvider {
    
    static private let id = CKRecord.ID(recordName: "F56C48BA-49CE-404D-87CC-4B6407D35089")
    static var previews: some View {
        ProfileView(userId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.light)
        ProfileView(userId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.dark)
    }
}
