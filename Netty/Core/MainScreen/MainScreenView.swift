//
//  MainScreenView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct MainScreenView: View {
    
    let userRecordId: CKRecord.ID?
    let logOutFunc: () async -> ()
    
    @State private var path: NavigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                    }
                    .tag(0)
                DirectView(userRecordId: userRecordId, path: $path)
                    .tabItem {
                        Image(systemName: "ellipsis.bubble")
                    }
                    .tag(1)
                ProfileView(userRecordId: userRecordId, logOutFunc: logOutFunc)
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .tag(2)
            }
            .navigationDestination(for: FindUserModel.self) { userModel in
                ChatView(for: userModel, ownId: userRecordId)
            }
            .toolbar(.hidden)
        }
    }
}








struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView(userRecordId: .init(recordName: "F56C48BA-49CE-404D-87CC-4B6407D35089"), logOutFunc: LogInAndOutViewModel().logOut)
        MainScreenView(userRecordId: .init(recordName: "F56C48BA-49CE-404D-87CC-4B6407D35089"), logOutFunc: LogInAndOutViewModel().logOut)
    }
}
