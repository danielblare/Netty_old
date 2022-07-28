//
//  ProfileView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct ProfileView: View {
    
    @State private var isLoading: Bool = false
    
    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
            
    var body: some View {
        ZStack {
            ZStack {
                VStack {
                    HStack {
                        
                        AvatarImageView(for: logInAndOutViewModel.userRecordId)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()

                        
                        Spacer(minLength: 0)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        Task {
                            isLoading = true
                            await vm.logOut()
                            isLoading = false
                        }
                    } label: {
                        Text("Log out")
                            .font(.title2)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.bordered)
                }
                
                
                
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
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
