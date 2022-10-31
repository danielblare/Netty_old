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
    
    @State private var showPhotoImportSheet: Bool = false
    @State private var photoInputSource: UIImagePickerController.SourceType = .camera
    @State private var showProfilePhotoChangingConfirmationDialog: Bool = false
    
    let userRecordId: CKRecord.ID?
    let logOutFunc: () async -> ()
    
    @StateObject private var vm: ProfileViewModel
    
    init(userRecordId: CKRecord.ID?, logOutFunc: @escaping () async -> ()) {
        self.userRecordId = userRecordId
        self.logOutFunc = logOutFunc
        self._vm = .init(wrappedValue: ProfileViewModel(id: userRecordId, logOutFunc: logOutFunc))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Image and full name
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
                    
                    Spacer(minLength: 0)
                }
            }
            .toolbar {
                getToolbar()
            }
            .refreshable {
                Task {
                    await vm.sync()
                }
            }
            .fullScreenCover(isPresented: $showPhotoImportSheet) {
                ImagePicker(source: photoInputSource) { image in
                    vm.uploadImage(image, for: userRecordId)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    @ToolbarContentBuilder private func getToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                ProfileSettingsView(vm: vm)
            } label: {
                Image(systemName: "gearshape")
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Profile")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
    
    private var ProfileImage: some View {
        ZStack {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if vm.isLoading {
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            } else {
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
            
            // Name
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
            } else {
                LoadingAnimation()
                    .padding(.vertical)
            }
            
            
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder private func getConfirmationActions() -> some View {
        Button("Remove current photo") {
            vm.uploadImage(nil, for: userRecordId)
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
    
    static private let id = CKRecord.ID(recordName: "2BF042AD-D7B5-4AEE-9328-D328E942B0FF")
    static var previews: some View {
        ProfileView(userRecordId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.light)
        ProfileView(userRecordId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.dark)
    }
}
