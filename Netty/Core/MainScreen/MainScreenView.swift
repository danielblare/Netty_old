//
//  MainScreenView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct TestUser {
    static let id: CKRecord.ID = .init(recordName: "30E1675A-A59C-4FB4-8A2A-5E99D197E736")
    
    static let userModel: UserModel = UserModel(id: id, firstName: "TestName", lastName: "TestLastNake", nickname: "TestNickname")
}

class MainScreenViewModel: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
} 

struct MainScreenView: View {
    
    enum TabSelection: String {
        case home, direct, profile
    }
    @StateObject private var vm = MainScreenViewModel()
    
    @State private var selection: TabSelection = TabSelection(rawValue: UserDefaults.standard.string(forKey: "selectedTab") ?? "") ?? .home {
        didSet {
            UserDefaults.standard.set(selection.rawValue, forKey: "selectedTab")
        }
    }
    
    // Current user's recordID
    let userId: CKRecord.ID
                
    var body: some View {
        NavigationStack(path: $vm.path) {
            TabView(selection: $selection) {
                HomeView(userId: userId)
                    .onAppear {
                        selection = .home
                    }
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                    }
                    .tag(TabSelection.home)
                DirectView(userId: userId)
                    .onAppear {
                        selection = .direct
                    }
                    .tabItem {
                        Image(systemName: "ellipsis.bubble")
                    }
                    .tag(TabSelection.direct)
                PrivateProfileView(userId: userId)
                    .onAppear {
                        selection = .profile
                    }
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .tag(TabSelection.profile)
            }
            .navigationDestination(for: UserModelHolder.self) { userModelHolder in
                switch userModelHolder.destination {
                case .chat:
                    ChatView(for: userModelHolder.userModel, ownId: userId)
                case .profile:
                    PublicProfileView(for: userModelHolder.userModel)
                }
            }
            .navigationTitle("Main")
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
