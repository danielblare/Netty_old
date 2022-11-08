//
//  PrivateProfileViewModel.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

class PrivateProfileViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    // Profile avatar image
    @Published var image: UIImage? = nil
    
    @Published var posts: [PostModel] = []
    
    // View is loading if true
    @Published var userInfoIsLoading: Bool = false
    @Published var profileImageIsLoading: Bool = true
    @Published var postsAreLoading: Bool = false
    @Published var postIsUploading: Bool = false
    
    // User's first name
    @Published var firstName: String = ""
    
    // User's last name
    @Published var lastName: String = ""
    
    // User's nickname
    @Published var nickname: String = ""
    
    // User's record ID
    let userId: CKRecord.ID
    
    // Cache manager to save some user's data in cache
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID) {
        userId = id
        getData()
    }
    
    /// Gets all user's data
    func getData() {
        Task {
            await getImage()
        }
        Task {
            await getUserData()
        }
        Task {
            await getPosts()
        }
    }
    
    func deletePost(_ post: PostModel) async {
        switch await PostsService.instance.deletePost(post) {
        case .success(let recordId):
            if let _ = recordId {
                await MainActor.run {
                    withAnimation {
                        posts.removeAll(where: { $0.id == post.id })
                        cacheManager.addTo(cacheManager.posts, key: "\(userId.recordName)_posts", value: PostModelsHolder(posts))
                    }
                }
            } else {
                showAlert(title: "Error deleting post", message: "")
            }
        case .failure(let error):
            showAlert(title: "Error deleting post", message: error.localizedDescription)
        }
    }
    
    /// Deletes user's data from cache and downloads new fresh data from database
    func sync() async {
        cacheManager.delete(from: cacheManager.photoCache, "_avatar", for: userId.recordName)
        getData()
    }
    
    private func getPosts() async {
        if let savedPostsHolder = cacheManager.getFrom(cacheManager.posts, key: userId.recordName) {
            await MainActor.run {
                withAnimation {
                    posts = savedPostsHolder.posts
                }
            }
            switch await PostsService.instance.getPostsForUserWith(userId) {
            case .success(let posts):
                if self.posts != posts {
                    cacheManager.addTo(cacheManager.posts, key: userId.recordName, value: PostModelsHolder(posts))
                    await MainActor.run {
                        withAnimation {
                            self.posts = posts
                        }
                    }
                }
            case .failure(_):
                break
            }
        } else {
            await MainActor.run {
                postsAreLoading = true
            }
            switch await PostsService.instance.getPostsForUserWith(userId) {
            case .success(let posts):
                cacheManager.addTo(cacheManager.posts, key: userId.recordName, value: PostModelsHolder(posts))
                await MainActor.run {
                    self.posts = posts
                    withAnimation {
                        postsAreLoading = false
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    posts = []
                    postsAreLoading = false
                }
                showAlert(title: "Error while loading posts", message: error.localizedDescription)
            }
        }
    }
    
    func newPost(_ image: UIImage?) async {
        if let image = image {
            
            await MainActor.run {
                postIsUploading = true
            }
            
            switch await PostsService.instance.addPostForUserWith(userId, image: image) {
            case .success(let postModel):
                posts.insert(postModel, at: 0)
            case .failure(let error):
                showAlert(title: "Error uploading new post", message: error.localizedDescription)
            }
            
            await MainActor.run {
                postIsUploading = false
            }
        }
    }
    
    private func getUserData() async {
        await MainActor.run {
            userInfoIsLoading = true
        }
        
        if let savedUser = cacheManager.getFrom(cacheManager.userData, key: userId.recordName) {
            await MainActor.run {
                firstName = savedUser.user.firstName
                lastName = savedUser.user.lastName
                nickname = savedUser.user.nickname
                
                userInfoIsLoading = false
            }
            switch await UserInfoService.instance.fetchUserDataForUser(with: userId) {
            case .success(let userModel):
                if let userModel = userModel, userModel != savedUser.user {
                    cacheManager.addTo(cacheManager.userData, key: userId.recordName, value: UserModelHolder(userModel))
                    await MainActor.run {
                        firstName = userModel.firstName
                        lastName = userModel.lastName
                        nickname = userModel.nickname
                        
                        userInfoIsLoading = false
                    }
                }
            case .failure(_):
                break
            }
        } else {
            switch await UserInfoService.instance.fetchUserDataForUser(with: userId) {
            case .success(let userModel):
                if let userModel = userModel {
                    cacheManager.addTo(cacheManager.userData, key: userId.recordName, value: UserModelHolder(userModel))
                    await MainActor.run {
                        firstName = userModel.firstName
                        lastName = userModel.lastName
                        nickname = userModel.nickname
                        
                        userInfoIsLoading = false
                    }
                } else {
                    showAlert(title: "Error while fetching user data", message: "Cannot fetch some parameters")
                    await MainActor.run {
                        userInfoIsLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching user data", message: error.localizedDescription)
                await MainActor.run {
                    userInfoIsLoading = false
                }
            }
        }
    }
    
    /// Gets current user's avatar
    private func getImage() async {
        
        // Checks if user's avatar already saved in cache
        if let savedImage = cacheManager.getFrom(cacheManager.photoCache, key: "\(userId.recordName)_avatar") {
            await MainActor.run {
                withAnimation {
                    image = savedImage
                }
            }
        } else {
            
            // Starts loading
            await MainActor.run {
                withAnimation {
                    profileImageIsLoading = true
                }
            }
            
            // Downloads user's avatar from database
            switch await AvatarImageService.instance.fetchAvatarForUser(with: userId) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        profileImageIsLoading = false
                        self.image = returnedValue
                    }
                    if let image = returnedValue { // Saves fetched data in the cache
                        cacheManager.addTo(cacheManager.photoCache, key: "\(userId.recordName)_avatar", value: image)
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    /// Uploads new image as user's avatar to database
    func uploadImage(_ image: UIImage?) {
        
        // Removes old image from the screen, starts loading
        DispatchQueue.main.async {
            withAnimation {
                self.image = nil
                self.profileImageIsLoading = true
            }
        }
        
        // Fetches the user from database
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: userId) { record, error in
            if let record = record { // Checks if record exists
                if let image = image { // Checks if image isn't nil
                    if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("avatar.jpg"),
                       let data = image.jpegData(compressionQuality: 0.2) { // Compresses image
                        do {
                            try data.write(to: url) // Writes compressed data
                            let asset = CKAsset(fileURL: url)
                            record[.avatarRecordField] = asset // Sets new image to avatar record field
                            
                            // Saves updated with new image record
                            Task {
                                let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                                await MainActor.run {
                                    withAnimation { // Stops loading and sets new image as avatar on the screen
                                        self.image = UIImage(data: data)
                                        self.profileImageIsLoading = false
                                    }
                                }
                                // Saves new image in the cache
                                self.cacheManager.addTo(self.cacheManager.photoCache, key: "\(self.userId.recordName)_avatar", value: image)
                            }
                        } catch {
                            self.showAlert(title: "Error while writing image", message: error.localizedDescription)
                        }
                    }
                } else { // Sets user's image to nil because image is broken
                    record[.avatarRecordField] = nil
                    Task { // Saves updated user to database
                        let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                        await MainActor.run {
                            withAnimation {
                                self.profileImageIsLoading = false
                            }
                        }
                        
                        // Deletes current avatar from the cache
                        self.cacheManager.delete(from: self.cacheManager.photoCache, "_avatar", for: record.recordID.recordName)
                    }
                }
            } else { // Fetching current avatar because cannot fetch user's record
                if let error = error {
                    self.showAlert(title: "Error while fetching user's record", message: error.localizedDescription)
                }
                
                Task {
                    await self.getImage()
                }
            }
        }
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
