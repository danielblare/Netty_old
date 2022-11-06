//
//  PostsService.swift
//  Netty
//
//  Created by Danny on 11/6/22.
//

import CloudKit
import SwiftUI

actor PostsService {
    private init() {}
    
    static let instance = PostsService()
    
    enum CustomError: Error {
        case errorWhileConvertingImage
    }
    
    private func getPostsReferencesForUserWith(_ id: CKRecord.ID) async -> Result<[CKRecord.Reference], Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedUser, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let user = returnedUser {
                    continuation.resume(returning: .success(user[.postsRecordField] as? [CKRecord.Reference] ?? []))
                }
            }
        }
    }
    
    func getPostsForUserWith(_ id: CKRecord.ID) async -> Result<[PostModel], Error> {
        switch await getPostsReferencesForUserWith(id) {
        case .success(let references):
            return await withCheckedContinuation { continuation in
                CKContainer.default().publicCloudDatabase.fetch(withRecordIDs: references.map({ $0.recordID })) { result in
                    switch result {
                    case .success(let records):
                        var postModels: [PostModel] = []
                        for result in records {
                            switch result.value {
                            case .success(let postRecord):
                                if let imageAsset = postRecord[.imageRecordField] as? CKAsset,
                                   let owner = postRecord[.ownerRecordField] as? CKRecord.Reference,
                                   let imageURL = imageAsset.fileURL,
                                   let data = try? Data(contentsOf: imageURL),
                                   let image = UIImage(data: data) {
                                    postModels.append(PostModel(id: postRecord.recordID, ownerId: owner.recordID, photo: Image(uiImage: image), creationDate: postRecord.creationDate ?? .now))
                                }
                            case .failure(let error):
                                continuation.resume(returning: .failure(error))
                            }
                        }
                        continuation.resume(returning: .success(postModels.sorted(by: { $0.creationDate > $1.creationDate })))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addPostForUserWith(_ id: CKRecord.ID, image: UIImage) async -> Result<PostModel, Error> {
        await withCheckedContinuation { continuation in
            let newPost = CKRecord(recordType: .postsRecordType)
            let owner = CKRecord.Reference.init(recordID: id, action: .none)
            if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("post.jpg"),
               let data = image.jpegData(compressionQuality: 1) {
                do {
                    try data.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    newPost[.imageRecordField] = asset
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            } else {
                continuation.resume(returning: .failure(CustomError.errorWhileConvertingImage))
            }
            newPost[.ownerRecordField] = owner
            CKContainer.default().publicCloudDatabase.save(newPost) { returnedPost, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let returnedPost = returnedPost {
                    CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedUser, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else if let returnedUser = returnedUser {
                            let newRef = CKRecord.Reference(recordID: returnedPost.recordID, action: .none)
                            if var posts = returnedUser[.postsRecordField] as? [CKRecord.Reference] {
                                posts.insert(newRef, at: 0)
                                returnedUser[.postsRecordField] = posts
                            } else {
                                returnedUser[.postsRecordField] = [newRef]
                            }
                            CKContainer.default().publicCloudDatabase.save(returnedUser) { returnedRecord, error in
                                if let error = error {
                                    continuation.resume(returning: .failure(error))
                                } else if let _ = returnedRecord {
                                    continuation.resume(returning: .success(PostModel(id: returnedPost.recordID, ownerId: owner.recordID, photo: Image(uiImage: image), creationDate: returnedPost.creationDate ?? .now)))
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}
