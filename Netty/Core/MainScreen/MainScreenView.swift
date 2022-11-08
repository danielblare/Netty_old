//
//  MainScreenView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

class MainScreenViewModel: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
} 

struct MainScreenView: View {
    
    @StateObject private var vm = MainScreenViewModel()
    
    // Current user's recordID
    let userId: CKRecord.ID
                
    var body: some View {
        NavigationStack(path: $vm.path) {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                    }
                    .tag(0)
                DirectView(userId: userId)
                    .tabItem {
                        Image(systemName: "ellipsis.bubble")
                    }
                    .tag(1)
                ProfileView(userId: userId)
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
        .environmentObject(vm)
    }
}








struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView(userId: TestUser.id)
        MainScreenView(userId: TestUser.id)
    }
}
