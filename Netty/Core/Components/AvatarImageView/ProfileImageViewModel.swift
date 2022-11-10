//
//  ProfileImageViewModel.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import SwiftUI
import CloudKit


class ProfileImageViewModel: ObservableObject {
    
    // Profile image
    @Published var image: UIImage? = nil
    
    // Shows loading view if true
    @Published var isLoading: Bool = false
    
    // Cache manager
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID) {
        Task {
            await getImage(for: id)
        }
    }
    
    /// Gets image for record id from database
    private func getImage(for id: CKRecord.ID) async {
        if let savedImage = cacheManager.getFrom(cacheManager.photoCache, key: "\(id.recordName)_avatar") {
            await MainActor.run {
                image = savedImage
            }
            switch await AvatarImageService.instance.fetchAvatarForUser(with: id) {
            case .success(let returnedValue):
                cacheManager.addTo(cacheManager.photoCache, key: "\(id.recordName)_avatar", value: returnedValue)
                await MainActor.run {
                    self.image = returnedValue
                }
            case .failure(_):
                break
            }
        } else {
            await MainActor.run {
                isLoading = true
            }
            switch await AvatarImageService.instance.fetchAvatarForUser(with: id) {
            case .success(let returnedValue):
                cacheManager.addTo(cacheManager.photoCache, key: "\(id.recordName)_avatar", value: returnedValue)
                await MainActor.run {
                    self.image = returnedValue
                }
            case .failure(_):
                break
            }
            await MainActor.run {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}
