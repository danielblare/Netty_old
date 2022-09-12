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
    
    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
    
    var body: some View {
        NavigationView {
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
                    vm.uploadImage(image, for: logInAndOutViewModel.userRecordId)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView()
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
                vm.sync(for: logInAndOutViewModel.userRecordId)
            }
        }
    }
}









struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(LogInAndOutViewModel())
            .preferredColorScheme(.light)
        ProfileView()
            .environmentObject(LogInAndOutViewModel())
            .preferredColorScheme(.dark)
    }
}
