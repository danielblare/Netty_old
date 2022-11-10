//
//  FollowersAndFollowingPageViewModel.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI
import CloudKit


final class FollowersAndFollowingPageViewModel: ObservableObject {
    
    @Published var users: [UserModel]? = nil
    
    @Published var isLoading: Bool = false
        
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""

    let ownId: CKRecord.ID
    
    init(refs: [CKRecord.Reference], ownId: CKRecord.ID) {
        self.ownId = ownId
        Task {
            await MainActor.run {
                isLoading = true
            }
            switch await UserInfoService.instance.fetchUserDataForUsers(with: refs.map({ $0.recordID })) {
            case .success(let userModels):
                await MainActor.run {
                    users = userModels
                    withAnimation {
                        isLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching data", message: error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    func follow(_ user: UserModel) async -> Result<Void, Error> {
        switch await UserInfoService.instance.follow(user, ownId: ownId) {
        case .success(_):
            if let oldInfo = CacheManager.instance.getFrom(CacheManager.instance.userData, key: ownId.recordName) {
                var following = oldInfo.user.following
                following.insert(CKRecord.Reference(recordID: user.id, action: .none), at: 0)

                let newInfo = UserModelHolder(UserModel(id: oldInfo.user.id, firstName: oldInfo.user.firstName, lastName: oldInfo.user.lastName, nickname: oldInfo.user.nickname, followers: oldInfo.user.followers, following: following))
                CacheManager.instance.addTo(CacheManager.instance.userData, key: ownId.recordName, value: newInfo)
            }
            if let oldInfo = CacheManager.instance.getFrom(CacheManager.instance.userData, key: user.id.recordName) {
                var followers = oldInfo.user.followers
                followers.insert(CKRecord.Reference(recordID: ownId, action: .none), at: 0)

                let newInfo = UserModelHolder(UserModel(id: oldInfo.user.id, firstName: oldInfo.user.firstName, lastName: oldInfo.user.lastName, nickname: oldInfo.user.nickname, followers: followers, following: oldInfo.user.following))
                CacheManager.instance.addTo(CacheManager.instance.userData, key: user.id.recordName, value: newInfo)
            }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func unfollow(_ user: UserModel) async -> Result<Void, Error> {
        switch await UserInfoService.instance.unfollow(user, ownId: ownId) {
        case .success(_):
            if let oldInfo = CacheManager.instance.getFrom(CacheManager.instance.userData, key: ownId.recordName) {
                var following = oldInfo.user.following
                following.removeAll(where: { $0.recordID == user.id })

                let newInfo = UserModelHolder(UserModel(id: oldInfo.user.id, firstName: oldInfo.user.firstName, lastName: oldInfo.user.lastName, nickname: oldInfo.user.nickname, followers: oldInfo.user.followers, following: following))
                CacheManager.instance.addTo(CacheManager.instance.userData, key: ownId.recordName, value: newInfo)
            }
            if let oldInfo = CacheManager.instance.getFrom(CacheManager.instance.userData, key: user.id.recordName) {
                var followers = oldInfo.user.followers
                followers.removeAll(where: { $0.recordID == ownId })

                let newInfo = UserModelHolder(UserModel(id: oldInfo.user.id, firstName: oldInfo.user.firstName, lastName: oldInfo.user.lastName, nickname: oldInfo.user.nickname, followers: followers, following: oldInfo.user.following))
                CacheManager.instance.addTo(CacheManager.instance.userData, key: user.id.recordName, value: newInfo)
            }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Shows alert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }

}
