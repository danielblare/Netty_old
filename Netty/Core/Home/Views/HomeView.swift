//
//  HomeView.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI
import CloudKit

struct HomeView: View {
        
    // View Model
    @StateObject private var vm: HomeViewModel
    
    @State private var sheetIsPresented: Bool = false
    
    init(userId: CKRecord.ID) {
        _vm = .init(wrappedValue: HomeViewModel(userId))
    }
        
    var body: some View {
        NavigationView {
            if !vm.isLoading {
                ScrollViewReader { proxy in
                    
                    ScrollView {
                        if vm.posts.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "newspaper")
                                    .imageScale(.large)
                                Text("No posts")
                            }
                            .font(.title)
                            .foregroundColor(.secondary)
                            .padding(.top, 200)
                        } else {
                            LazyVStack {
                                ForEach(vm.posts) { post in
                                    PostView(postModel: post)
                                        .id(post.id)
                                        .onAppear {
                                            print("appearing")
                                            vm.getMorePostsIfNeeded(post)
                                        }
                                }
                                if vm.downloadingMorePosts {
                                    ProgressView()
                                        .padding(.bottom)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await vm.sync()
                    }
                    .toolbar { getToolbar(proxy) }
                }
                .sheet(isPresented: $sheetIsPresented) {
                    NavigationStack {
                        FindUserView(ownId: vm.ownId, forDestination: .profile, finishPickingFunc: findUserFinishPicking)
                            .navigationTitle("Find User")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .padding(.top)
                }
            }
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}) {
            Text(vm.alertMessage)
        }
    }
    
    private func findUserFinishPicking() {
        sheetIsPresented = false
    }
    
    // Creates toolbar for navigation view
    @ToolbarContentBuilder private func getToolbar(_ proxy: ScrollViewProxy) -> some ToolbarContent {
        
        // Title
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Feed")
                .onTapGesture {
                    withAnimation {
                        proxy.scrollTo(vm.posts.first?.id)
                    }
                }
                .fontWeight(.semibold)
                .font(.title)
                .foregroundColor(.accentColor)
        }
        
        // New message button
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                sheetIsPresented = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
        }
    }

}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(userId: TestUser.daniel.id)
            .preferredColorScheme(.dark)
        HomeView(userId: TestUser.daniel.id)
            .preferredColorScheme(.light)
    }
}
