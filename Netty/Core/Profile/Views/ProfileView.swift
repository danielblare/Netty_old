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
        self.vm = ProfileViewModel(id: userRecordId)
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
                        
                        VStack {
                            
                            // Name
                            if let fullName = vm.fullName {
                                Text(fullName)
                                    .lineLimit(1)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            } else {
                                LoadingAnimation()
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
                        ProfileSettingsView(logOutFunc: logOutFunc)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if let nickname = vm.nickname {
                        HStack {
                            Text(nickname)
                                .foregroundColor(.primary)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer(minLength: 70)
                        }
                    } else {
                        LoadingAnimation()
                    }
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
    static var previews: some View {
        ProfileView(userRecordId: LogInAndOutViewModel().userRecordId, logOutFunc: LogInAndOutViewModel().logOut)
            .preferredColorScheme(.light)
        ProfileView(userRecordId: LogInAndOutViewModel().userRecordId, logOutFunc: LogInAndOutViewModel().logOut)
            .preferredColorScheme(.dark)
    }
}
