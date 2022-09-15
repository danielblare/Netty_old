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
    
    @State private var showSheet: Bool = false
    
    let userRecordId: CKRecord.ID?
    let logOutFunc: () async -> ()

    @ObservedObject private var vm: ProfileViewModel
    
    init(userRecordId: CKRecord.ID?, logOutFunc: @escaping () async -> ()) {
        self.userRecordId = userRecordId
        self.logOutFunc = logOutFunc
        self.vm = ProfileViewModel(id: userRecordId, logOutFunc: logOutFunc)
    }
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    // Image and full name
                    HStack {
                        
                        // Image
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
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.horizontal)
                        .onTapGesture {
                            showSheet = true
                        }
                        
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
                        .padding(.vertical)
                        .frame(height: 100)
                        
                        Spacer(minLength: 0)
                        
                    }
                    .padding(.vertical)
                    
                    
                    Spacer(minLength: 0)
                }
            }
            .sheet(isPresented: $showSheet) {
                ImagePicker { image in
                    vm.uploadImage(image, for: userRecordId)
                }
            }
            .toolbar {
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
            .refreshable {
                Task {
                    await vm.fullSync()
                }
            }
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
