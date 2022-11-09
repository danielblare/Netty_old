//
//  FollowersPageView.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI
import CloudKit

struct FollowersPageView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var vm: FollowersPageViewModel
    
    @State private var searchText: String = ""
    
    init(refs: [CKRecord.Reference], ownId: CKRecord.ID) {
        _vm = .init(wrappedValue: FollowersPageViewModel(refs: refs, ownId: ownId))
    }
    
    var body: some View {
        ZStack {
            if let followers = searchResults {
                if followers.isEmpty {
                    Text("You have no followers yet")
                        .foregroundColor(.secondary)
                        .font(.title2)
                        .frame(height: 200)
                }
                List(followers) { follower in
                    FollowerRowView(model: follower, isFollowed: follower.followers.contains(where: { $0.recordID == vm.ownId }))
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                .listStyle(.plain)
                
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
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Filters messages to satisfy search request
    private var searchResults: [UserModel]? {
        if searchText.isEmpty {
            return vm.followers
        } else {
            return vm.followers?.filter { $0.nickname.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct FollowersPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FollowersPageView(refs: [], ownId: .init(recordName: "A6244FDA-A0DA-47CB-8E12-8F2603271899"))
        }
    }
}
