//
//  FollowersAndFollowingPageView.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI
import CloudKit

struct FollowersAndFollowingPageView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var vm: FollowersAndFollowingPageViewModel
    
    @State private var searchText: String = ""
    
    private let destination: RefDestination
    
    init(holder: RefsHolderWithDestination, ownId: CKRecord.ID) {
        destination = holder.destination
        _vm = .init(wrappedValue: FollowersAndFollowingPageViewModel(refs: holder.refs, ownId: ownId))
    }
    
    var body: some View {
        ZStack {
            if let users = vm.users {
                List(searchResults(users: users)) { user in
                    UserWithFollowButtonRowView(model: user, isFollowed: user.followers.contains(where: { $0.recordID == vm.ownId }), followFunc: vm.follow, unfollowFunc: vm.unfollow)
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .listStyle(.plain)
                
                if users.isEmpty {
                    Text(getEmptyText())
                        .foregroundColor(.secondary)
                        .font(.title2)
                        .frame(height: 200)
                }

            }
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .disabled(vm.isLoading)
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        }, message: {
            Text(vm.alertMessage)
        })
        .navigationTitle(getTitle())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getEmptyText() -> String {
        switch destination {
        case .following:
            return "You are not following anyone"
        case .followers:
            return "You have no followers yet"
        }
    }
    
    private func getTitle() -> String {
        switch destination {
        case .following:
            return "Following"
        case .followers:
            return "Followers"
        }
    }
    // Filters messages to satisfy search request
    private func searchResults(users: [UserModel]) -> [UserModel] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.nickname.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct FollowersPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FollowersAndFollowingPageView(holder: RefsHolderWithDestination(destination: .followers, refs: [CKRecord.Reference.init(recordID: TestUser.anastasia.id, action: .none)]), ownId: TestUser.daniel.id)
        }
    }
}
