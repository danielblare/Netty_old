//
//  PostViewModel.swift
//  Netty
//
//  Created by Danny on 11/6/22.
//

import SwiftUI
import CloudKit

class PostViewModel: ObservableObject {
    
    let postModel: PostModel
    @Published var nickname: String? = nil
    @Published var liked: Bool = true
    @Published var saved: Bool = true
    
    init(postModel: PostModel) {
        self.postModel = postModel
        Task {
            switch await UserInfoService.instance.fetchNicknameForUser(with: postModel.ownerId) {
            case .success(let nickname):
                await MainActor.run {
                    self.nickname = nickname
                }
            case .failure(_):
                break
            }
        }
    }
}
