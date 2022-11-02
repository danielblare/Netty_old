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
        getImage(for: id)
    }

    /// Gets image for record id from database
    private func getImage(for id: CKRecord.ID) {
        if let savedImage = cacheManager.getFrom(cacheManager.photoCache, key: "\(id.recordName)_avatar") {
            image = savedImage
            Task {
                switch await AvatarImageService.instance.fetchAvatarForUser(with: id) {
                case .success(let returnedValue):
                    await MainActor.run(body: {
                        cacheManager.addTo(cacheManager.photoCache, key: "\(id.recordName)_avatar", value: returnedValue)
                        self.image = returnedValue
                    })
                case .failure(_):
                    break
                }
            }
        } else {
            isLoading = true
            Task {
                switch await AvatarImageService.instance.fetchAvatarForUser(with: id) {
                case .success(let returnedValue):
                    await MainActor.run(body: {
                        withAnimation {
                            isLoading = false
                            self.image = returnedValue
                        }
                        if let image = returnedValue {
                            cacheManager.addTo(cacheManager.photoCache, key: "\(id.recordName)_avatar", value: image)
                        }
                    })
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }   
}
