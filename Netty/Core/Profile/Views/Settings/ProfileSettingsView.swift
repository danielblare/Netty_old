//
//  ProfileSettingsView.swift
//  Netty
//
//  Created by Danny on 9/12/22.
//

import SwiftUI
import CloudKit

struct ProfileSettingsView: View {
    
    @ObservedObject var vm: ProfileViewModel
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    PersonalInfoPage(id: vm.userRecordId)
                } label: {
                    HStack {
                        Text("Personal Information")
                        
                        Image(systemName: "person.crop.circle")
                        
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            // Log Out
            Section {
                Button(role: .destructive, action: {
                    Task {
                        isLoading = true
                        await vm.logOut()
                        isLoading = false
                    }
                }) {
                    Text("Log Out")
                }
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
}

struct ProfileSettingsView_Previews: PreviewProvider {
    
    static private let id = CKRecord.ID(recordName: "2BF042AD-D7B5-4AEE-9328-D328E942B0FF")
    
    static var previews: some View {
        NavigationStack {
            ProfileSettingsView(vm: ProfileViewModel(id: id, logOutFunc: LogInAndOutViewModel(id: id).logOut))
        }
    }
}
