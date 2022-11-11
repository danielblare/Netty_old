//
//  PublicProfileViewModel.swift
//  Netty
//
//  Created by Danny on 11/8/22.
//

import SwiftUI
import Combine
import CloudKit

class PublicProfileViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""

    let user: UserModel
    
    private let ownId: CKRecord.ID
    
    @Published var userInfoIsLoading: Bool = false
    @Published var postsAreLoading: Bool = true
    
    // Posts array
    @Published var posts: [PostModel] = []
    
    // User's first name
    @Published var firstName: String = ""
    
    // User's last name
    @Published var lastName: String = ""
    
    // User's nickname
    @Published var nickname: String = ""
    
    @Published var followers: [CKRecord.Reference]? = nil
    
    @Published var following: [CKRecord.Reference]? = nil

    @Published var isFollowed: Bool? = nil
    @Published var followButtonIsLoading: Bool = false

    @Published var postsNumber: String? = nil
        
    private let cacheManager = CacheManager.instance
    
    private var cancellables = Set<AnyCancellable>()
    
    init(_ userModel: UserModel, ownId: CKRecord.ID) {
        user = userModel
        self.ownId = ownId
        addSubs()
        Task {
            await sync()
        }
    }
    
    func followButtonPressed() {
        if let isFollowed = isFollowed {
            if isFollowed {
                Task {
                    await MainActor.run {
                        followButtonIsLoading = true
                    }
                    
                    switch await UserInfoService.instance.unfollow(user, ownId: ownId) {
                    case .success(_):
                        await MainActor.run {
                            self.isFollowed = false
                            followers?.removeAll(where: { $0.recordID == ownId })
                        }
                    case .failure(let error):
                        HapticManager.instance.notification(of: .error)
                        showAlert(title: "Error while unfollowing", message: error.localizedDescription)
                    }
                    await MainActor.run {
                        withAnimation {
                            followButtonIsLoading = false
                        }
                    }
                }
                
            } else {
                Task {
                    await MainActor.run {
                        followButtonIsLoading = true
                    }
                    
                    switch await UserInfoService.instance.follow(user, ownId: ownId) {
                    case .success(_):
                        await MainActor.run {
                            self.isFollowed = true
                            followers?.append(CKRecord.Reference(recordID: ownId, action: .none))
                        }
                    case .failure(let error):
                        HapticManager.instance.notification(of: .error)
                        showAlert(title: "Error while following", message: error.localizedDescription)
                    }
                    await MainActor.run {
                        withAnimation {
                            followButtonIsLoading = false
                        }
                    }
                }
                
            }
        }
    }
    
    private func addSubs() {
        $posts
            .sink(receiveValue: { self.postsNumber = "\($0.count)" })
            .store(in: &cancellables)
    }
    
    private func getUserData() async {
        if let savedUser = cacheManager.getFrom(cacheManager.userData, key: user.id.recordName) {
            await MainActor.run {
                firstName = savedUser.user.firstName
                lastName = savedUser.user.lastName
                nickname = savedUser.user.nickname
                isFollowed = savedUser.user.followers.contains(where: { $0.recordID == ownId })
                followers = savedUser.user.followers
                following = savedUser.user.following

            }
            switch await UserInfoService.instance.fetchUserDataForUser(with: user.id) {
            case .success(let userModel):
                if userModel != savedUser.user {
                    cacheManager.addTo(cacheManager.userData, key: user.id.recordName, value: UserModelHolder(userModel))
                    await MainActor.run {
                        firstName = userModel.firstName
                        lastName = userModel.lastName
                        nickname = userModel.nickname
                        isFollowed = userModel.followers.contains(where: { $0.recordID == ownId })
                        followers = userModel.followers
                        following = userModel.following

                    }
                }
            case .failure(_):
                break
            }
        } else {
            await MainActor.run {
                userInfoIsLoading = true
                followButtonIsLoading = true
            }
            

            switch await UserInfoService.instance.fetchUserDataForUser(with: user.id) {
            case .success(let userModel):
                cacheManager.addTo(cacheManager.userData, key: user.id.recordName, value: UserModelHolder(userModel))
                await MainActor.run {
                    firstName = userModel.firstName
                    lastName = userModel.lastName
                    nickname = userModel.nickname
                    isFollowed = userModel.followers.contains(where: { $0.recordID == ownId })
                    followers = userModel.followers
                    following = userModel.following

                    userInfoIsLoading = false
                    followButtonIsLoading = false
                }
            case .failure(let error):
                showAlert(title: "Error while fetching user data", message: error.localizedDescription)
                await MainActor.run {
                    userInfoIsLoading = false
                    followButtonIsLoading = false
                }
            }
        }
    }
    
    private func getUserPosts() async {
        
        if let savedPosts = cacheManager.getFrom(cacheManager.posts, key: user.id.recordName) {
            
            await MainActor.run {
                if savedPosts.posts != posts {
                    posts = savedPosts.posts
                }
                withAnimation {
                    postsAreLoading = false
                }
            }
            
            
            switch await PostsService.instance.getPostsForUserWith(user.id) {
            case .success(let postArray):
                if postArray != savedPosts.posts {
                    cacheManager.addTo(cacheManager.posts, key: user.id.recordName, value: PostModelsHolder(postArray))
                    await MainActor.run {
                        withAnimation {
                            posts = postArray
                        }
                    }
                }
            case .failure(_):
                break
            }
            
        } else {
            switch await PostsService.instance.getPostsForUserWith(user.id) {
            case .success(let postArray):
                cacheManager.addTo(cacheManager.posts, key: user.id.recordName, value: PostModelsHolder(postArray))
                await MainActor.run {
                    posts = postArray
                    withAnimation {
                        postsAreLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching posts", message: error.localizedDescription)
                await MainActor.run {
                    postsAreLoading = false
                }
            }
        }
    }
    
    func updateValuesFromCache() {
        if let savedUser = cacheManager.getFrom(cacheManager.userData, key: user.id.recordName) {
            withAnimation {
                firstName = savedUser.user.firstName
                lastName = savedUser.user.lastName
                nickname = savedUser.user.nickname
                followers = savedUser.user.followers
                following = savedUser.user.following
            }
        }
        if let savedPostsHolder = cacheManager.getFrom(cacheManager.posts, key: user.id.recordName) {
            if savedPostsHolder.posts != posts {
                withAnimation {
                    posts = savedPostsHolder.posts
                }
            }
        }
    }
    
    /// Deletes user's data from cache and downloads new fresh data from database
    func sync() async {
        await getUserData()
        await getUserPosts()
    }
    
    /// Shows alert on the screen
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }

}
