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
    
    
    @Published var image: UIImage? = nil
    @Published var isLoading: Bool = false
    
    init(id: CKRecord.ID?) {
        getImage(for: id)
    }


    private func getImage(for id: CKRecord.ID?) {
        guard let id = id else { return }
        if let savedImage = CacheManager.instance.getImageFromDirectCache(key: "\(id.recordName)_avatar") {
            image = savedImage
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
                            CacheManager.instance.addToDirectPhotoCache(key: "\(id.recordName)_avatar", value: image)
                        }
                    })
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }   
}
