//
//  PublicProfileView.swift
//  Netty
//
//  Created by Danny on 11/8/22.
//

import SwiftUI
import CloudKit

struct PublicProfileView: View {
    
    // View Model
    @StateObject private var vm: PublicProfileViewModel
    
    init(for userModel: UserModel) {
        self._vm = .init(wrappedValue: PublicProfileViewModel(userModel))
    }
    
    
    var body: some View {
        ScrollView {
            HStack {
                
                
                ProfileImageView(for: vm.user.id)
                    .frame(width: 100, height: 100)
                    .padding(.horizontal)
                
                UserInfo
                    .padding(.vertical)
                    .frame(height: 100)
                
                
                Spacer(minLength: 0)
            }
            .padding(.vertical)
            
            Divider()
            
            Posts
        }
        .navigationTitle(vm.user.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            Task {
                await vm.sync()
            }
        }
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}) {
            Text(vm.alertMessage)
        }
    }
    
    @ViewBuilder
    private var Posts: some View {
        if !vm.postsAreLoading {
            
            if vm.posts.isEmpty {
                Text("User has no posts yet")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.top)

            } else {
                LazyVGrid(columns: .init(repeating: GridItem(spacing: 1), count: 3), spacing: 1) {
                    ForEach(vm.posts) { post in
                        NavigationLink {
                            PostView(postModel: post)
                        } label: {
                            Image(uiImage: post.photo)
                                .resizable()
                                .scaledToFit()
                        }
                        .contextMenu {
                            Button("Test Button") {
                                print("test")
                            }
                        } preview: {
                            PostView(postModel: post)
                        }
                        
                    }
                }

            }
        } else {
            ProgressView()
                .padding(.top, 100)
        }
    }
    
    private var UserInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            
            if vm.userInfoIsLoading {
                LoadingAnimation()
                    .padding(.vertical)
                
            } else { // User data
                
                Text("\(vm.firstName) \(vm.lastName)")
                    .lineLimit(1)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(vm.nickname)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 30) {
                    
                    VStack {
                        Text("Posts")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                    
                    VStack {
                        Text("Followers")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                    
                    VStack {
                        Text("Following")
                            .fontWeight(.semibold)
                            .font(.footnote)
                        
                        Text("***")
                            .font(.callout)
                    }
                }
                .padding(.top)
            }
            Spacer(minLength: 0)
        }
    }
}





struct PublicProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PublicProfileView(for: TestUser.userModel)
        }
    }
}
