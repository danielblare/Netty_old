//
//  MainScreenView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct MainScreenView: View {
    
    // Current user's recordID
    let userId: CKRecord.ID
    
    // Log out func passed from LogInAndOutViewModel
    let logOutFunc: () async -> ()
    
    // Navigation path
    @State private var path: NavigationPath = NavigationPath()
    
    @State private var directBadge: Int = UIApplication.shared.applicationIconBadgeNumber
    
    var body: some View {
        NavigationStack(path: $path) {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                    }
                    .tag(0)
                DirectView(userId: userId, path: $path)
                    .onAppear {
                        directBadge = 0
                        let resetBadge = CKModifyBadgeOperation(badgeValue: 0)
                        resetBadge.modifyBadgeCompletionBlock = { (error) -> Void in
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                Task {
                                    await MainActor.run {
                                        UIApplication.shared.applicationIconBadgeNumber = 0
                                    }
                                }
                            }
                        }
                        CKContainer.default().add(resetBadge)
                    }
                    .badge(directBadge)
                    .tabItem {
                        Image(systemName: "ellipsis.bubble")
                    }
                    .tag(1)
                ProfileView(userId: userId, logOutFunc: logOutFunc)
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .tag(2)
            }
            .navigationDestination(for: UserModel.self) { userModel in
                ChatView(for: userModel, ownId: userId)
            }
            .toolbar(.hidden)
        }
    }
}








struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView(userId: TestUser.id, logOutFunc: LogInAndOutViewModel().logOut)
        MainScreenView(userId: TestUser.id, logOutFunc: LogInAndOutViewModel().logOut)
    }
}
