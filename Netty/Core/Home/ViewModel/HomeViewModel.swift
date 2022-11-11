//
//  HomeViewModel.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI
import CloudKit

class HomeViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    private let hourStep: Int = 12
    private var hoursForPosts: Int
    
    @Published var posts: [PostModel] = []
    
    @Published var isLoading: Bool = true
    @Published var downloadingMorePosts: Bool = false
    
    let ownId: CKRecord.ID
    
    private let postsService = PostsService.instance
    private let userInfoService = UserInfoService.instance
    private let cacheManager = CacheManager.instance

    init(_ userId: CKRecord.ID) {
        ownId = userId
        hoursForPosts = hourStep
        Task {
            await sync()
        }
    }
    
    func sync() async {
        await getData()
    }
    
    private func getData() async {
        if let holder = cacheManager.getFrom(cacheManager.userData, key: ownId.recordName) {
            await getPosts(holder.user.following)
            
            switch await userInfoService.fetchUserDataForUser(with: ownId) {
            case .success(let newUser):
                if newUser != holder.user {
                    cacheManager.addTo(cacheManager.userData, key: ownId.recordName, value: UserModelHolder(newUser))
                    await getPosts(newUser.following)
                }
            case .failure(_):
                break
            }
        } else {
            switch await userInfoService.fetchUserDataForUser(with: ownId) {
            case .success(let user):
                cacheManager.addTo(cacheManager.userData, key: ownId.recordName, value: UserModelHolder(user))
                await getPosts(user.following)
            case .failure(let error):
                showAlert(title: "Error while fetching users you follow", message: error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    func getMorePostsIfNeeded(_ post: PostModel) {
        if let index = posts.firstIndex(of: post) {
            if index > posts.count - 6 {
                if !downloadingMorePosts {
                    Task {
                        await getMorePosts()
                    }
                }
            }
        }
    }
    
    private func getMorePosts() async {
        guard let from = Calendar.current.date(byAdding: .hour, value: -hoursForPosts, to: .now) as? NSDate,
              let to = Calendar.current.date(byAdding: .hour, value: -(hoursForPosts - hourStep), to: .now) as? NSDate,
              let holder = cacheManager.getFrom(cacheManager.userData, key: ownId.recordName) else {
            showAlert(title: "Error", message: "Error while fetching current date")
            return
        }

        await MainActor.run {
            downloadingMorePosts = true
        }
        print("Downloading more")
        switch await postsService.getPostsForUsersWith(holder.user.following, from: from, to: to) {
        case .success(let models):
            let filtered = models.filter({ model in
                !posts.contains(where: { $0.id == model.id })
            })
            hoursForPosts += hourStep
            
            if filtered.isEmpty && hoursForPosts < 5 * hourStep {
                await getMorePosts()
            } else {
                await MainActor.run {
                    downloadingMorePosts = false
                    withAnimation {
                        posts.append(contentsOf: filtered)
                    }
                }
            }
        case .failure(let error):
            showAlert(title: "Error fetching posts", message: error.localizedDescription)
            await MainActor.run {
                downloadingMorePosts = false
            }
        }
    }
    
    private func getPosts(_ following: [CKRecord.Reference]) async {
        guard let from = Calendar.current.date(byAdding: .hour, value: -hourStep, to: .now) as? NSDate,
        let to = Calendar.current.date(byAdding: .hour, value: 0, to: .now) as? NSDate else {
            showAlert(title: "Error", message: "Error while fetching current date")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        print("Downloading")
        switch await postsService.getPostsForUsersWith(following, from: from, to: to) {
        case .success(let models):
            hoursForPosts = hourStep
            await MainActor.run {
                withAnimation {
                    posts = models
                    isLoading = false
                }
            }
        case .failure(let error):
            showAlert(title: "Error fetching posts", message: error.localizedDescription)
            await MainActor.run {
                isLoading = false
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
