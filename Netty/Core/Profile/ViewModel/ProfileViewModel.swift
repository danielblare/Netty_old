//
//  ProfileViewModel.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    @Published var isLoading: Bool = false

        
    init() {
        
    }
    
    func uploadImage(_ image: UIImage, for id: CKRecord.ID?) {
        guard let id = id else { return }
        self.image = nil
        isLoading = true
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { record, error in
            if let record = record,
               let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("avatar.jpg") {
                let data = image.jpegData(compressionQuality: 0.5)
                
                do {
                    try data?.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    record[.avatarRecordField] = asset
                    Task {
                        let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                        self.image = image
                        self.isLoading = false
                        PhotoModelFileManager.instance.add(key: "avatar", value: image)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                self.getImage(for: id)
            }
        }
    }
    
    func getImage(for id: CKRecord.ID?) {
        if let savedImage = PhotoModelFileManager.instance.get(key: "avatar") {
            image = savedImage
        } else {
            isLoading = true
            guard let id = id else {
                isLoading = false
                return
            }
            Task {
                let result = await AvatarImageService.instance.fetchAvatarForUser(with: id)
                switch result {
                case .success(let returnedValue):
                    await MainActor.run(body: {
                        isLoading = false
                        self.image = returnedValue
                        if let image = returnedValue {
                            PhotoModelFileManager.instance.add(key: "avatar", value: image)
                        }
                    })
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
