//
//  ProfileSettingsView.swift
//  Netty
//
//  Created by Danny on 9/12/22.
//

import SwiftUI
import CloudKit

struct ProfileSettingsView: View {
    
    @EnvironmentObject private var logInAndOutVm: LogInAndOutViewModel
    
    // View model
    @ObservedObject var vm: PrivateProfileViewModel
    
    // Shows loading view if true
    @State private var isLoading: Bool = false
    
    var body: some View {
        
        // Settings list
        List {
            
            // Settings section
            Section {
                NavigationLink {
                    PersonalInfoPage(id: vm.userId)
                } label: {
                    HStack {
                        Text("Personal Information")
                        
                        Image(systemName: "person.crop.circle")
                        
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            Section {
                NavigationLink {
                    PrivacyAndSecurityPage()
                } label: {
                    HStack {
                        Text("Privacy & Security")
                        
                        Image(systemName: "lock.shield")
                        
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            // Log Out section
            Section {
                Button(role: .destructive) {
                    Task {
                        isLoading = true
                        await logInAndOutVm.logOut()
                        isLoading = false
                    }
                } label: {
                    HStack {
                        Text("Log Out")
                        
                        Spacer(minLength: 0)
                        
                        Image(systemName: "iphone.and.arrow.forward")
                    }
                }
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
        
    static var previews: some View {
        NavigationStack {
            ProfileSettingsView(vm: PrivateProfileViewModel(id: TestUser.daniel.id))
        }
    }
}
