//
//  ProfileView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit
import PhotosUI


/*
 Transfer id and logOut func throug views as a variable
 */



struct ProfileView: View {
    
    @State private var showSheet: Bool = false
    
    let userRecordId: CKRecord.ID?
    let logOutFunc: () async -> ()

    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
        
    var body: some View {
        NavigationStack {
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
                    .padding()
                    .onTapGesture {
                        showSheet = true
                    }
                    
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
                
                
                Spacer(minLength: 0)
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
            .onAppear {
                vm.sync(for: userRecordId)
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
