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
    
    enum PhotoImport {
        case avatar, post
    }
    
    
    // Presenting sheet to let user choose new avatar photo
    @State private var showPhotoImportSheet: Bool = false
    
    // Source of input photo
    @State private var photoInputSource: UIImagePickerController.SourceType = .camera
    @State private var importFor: PhotoImport = .post {
        didSet {
            showConfirmationDialog = true
        }
    }
    
    // Shows dialog with options to choose new photo from library, take new photo, remove current avatar
    @State private var showConfirmationDialog: Bool = false

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
                                importFor = .avatar
                            }
                        
                        
                        UserInfo
                            .padding(.vertical)
                            .frame(height: 100)
                        
                        Spacer(minLength: 0)
                        
                    }
                    .padding(.vertical)
                    
                    AddPost
                                        
                    Divider()

                    Posts
                    
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
                        switch importFor {
                        case .avatar:
                            vm.uploadImage(image)
                        case .post:
                            Task {
                                await vm.newPost(image)
                            }
                        }
                    }
                    .ignoresSafeArea()
                }
                .confirmationDialog("", isPresented: $showConfirmationDialog, titleVisibility: .hidden) {
                    getConfirmationActions()
                }
            }
        }
    }
    
    private var AddPost: some View {
        HStack {
            Spacer(minLength: 0)
            
            if vm.postIsUploading {
                ProgressView()
                    .scaleEffect(0.7)
            }
            
            Button {
                importFor = .post
            } label: {
                Label("Add post", systemImage: "plus")
                    .font(.callout)
            }
            .disabled(vm.postsAreLoading || vm.postIsUploading)
        }
        .padding(.horizontal)
    }
    
    private var Posts: some View {
        ZStack {
            if !vm.postsAreLoading {

                if vm.posts.isEmpty {

                    Text("No posts yet")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top)

                } else {
                    LazyVGrid(columns: .init(repeating: GridItem(spacing: 1), count: 3), spacing: 1) {
                        ForEach(vm.posts) { post in
                            NavigationLink(value: post) {
                                Image(uiImage: post.photo)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                }
            } else {
                ProgressView()
                    .padding(.top, 100)
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
            } else if vm.profileImageIsLoading { // loading view
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
        VStack(alignment: .leading, spacing: 5) {
            
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
                
                HStack(spacing: 30) {
                                        
                    VStack {
                        Text("Posts")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                    
                    VStack {
                        Text("Followers")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                    
                    VStack {
                        Text("Following")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                }
                .padding(.top)
                
            } else { // loading view
                LoadingAnimation()
                    .padding(.vertical)
            }

            Spacer(minLength: 0)
        }
    }
    
    // Creates confirmation dialog with options to select new avatar
    @ViewBuilder private func getConfirmationActions() -> some View {
        
        if importFor == .avatar {
            Button("Remove current photo") {
                vm.uploadImage(nil)
            }
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
    
    static private let id = CKRecord.ID(recordName: "A6244FDA-A0DA-47CB-8E12-8F2603271899")
    static var previews: some View {
        ProfileView(userId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.light)
        ProfileView(userId: id, logOutFunc: LogInAndOutViewModel(id: id).logOut)
            .preferredColorScheme(.dark)
    }
}
