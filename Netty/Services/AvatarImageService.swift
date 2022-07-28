//
//  AvatarImageService.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import SwiftUI
import CloudKit

actor AvatarImageService {
    
    
    static let instance = AvatarImageService()
    
    private init() {}
    
    func fetchAvatarForUser(with id: CKRecord.ID) async -> Result<UIImage?, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedrecord, error in
                if let returnedrecord = returnedrecord {
                    if let imageAsset = returnedrecord[.avatarRecordField] as? CKAsset,
                       let imageURL = imageAsset.fileURL,
                       let data = try? Data(contentsOf: imageURL),
                       let image = UIImage(data: data) {
                        continuation.resume(returning: .success(image))
                    } else {
                        continuation.resume(returning: .success(nil))
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
