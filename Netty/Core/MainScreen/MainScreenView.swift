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
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                }
                .tag(0)
            DirectView()
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
    }
}








struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView(userRecordId: LogInAndOutViewModel().userRecordId, logOutFunc: LogInAndOutViewModel().logOut)
            .preferredColorScheme(.dark)
        MainScreenView(userRecordId: LogInAndOutViewModel().userRecordId, logOutFunc: LogInAndOutViewModel().logOut)
            .preferredColorScheme(.light)
    }
}
