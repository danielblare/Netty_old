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
        case errorWhileConvertingImage, dataError
    }
    
    func deletePost(_ post: PostModel) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: post.ownerId) { returnedUser, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let user = returnedUser,
                          var posts = user[.postsRecordField] as? [CKRecord.Reference] {
                    posts.removeAll(where: { $0.recordID == post.id })
                    user[.postsRecordField] = posts
                    CKContainer.default().publicCloudDatabase.save(user) { returnedUser, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else {
                            CKContainer.default().publicCloudDatabase.delete(withRecordID: post.id) { returnedRecord, error in
                                if let error = error {
                                    continuation.resume(returning: .failure(error))
                                } else {
                                    continuation.resume(returning: .success(()))
                                }
                            }
                        }
                    }
                } else {
                    continuation.resume(returning: .failure(CustomError.dataError))
                }
            }
        }
    }
    
    func getPostsForUserWith(_ id: CKRecord.ID) async -> Result<[PostModel], Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "\(String.ownerRecordField) == %@", CKRecord.Reference(recordID: id, action: .none))
            let query = CKQuery(recordType: .postsRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query) { completion in
                switch completion {
                case .success(let results):
                    var postModels: [PostModel] = []
                    for result in results.matchResults {
                        switch result.1 {
                        case .success(let postRecord):
                            if let imageAsset = postRecord[.imageRecordField] as? CKAsset,
                               let owner = postRecord[.ownerRecordField] as? CKRecord.Reference,
                               let imageURL = imageAsset.fileURL,
                               let data = try? Data(contentsOf: imageURL),
                               let image = UIImage(data: data) {
                                postModels.append(PostModel(id: postRecord.recordID, ownerId: owner.recordID, photo: image, creationDate: postRecord.creationDate ?? .now))
                            }
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                            return
                        }
                    }
                    continuation.resume(returning: .success(postModels.sorted(by: { $0.creationDate > $1.creationDate })))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    
    func getPostsForUsersWith(_ refs: [CKRecord.Reference], from: NSDate, to: NSDate) async -> Result<[PostModel], Error> {
        await withCheckedContinuation { continuation in
            if refs.isEmpty {
                continuation.resume(returning: .success([]))
                return
            }
            let refPredicate = NSPredicate(format: "%K IN %@", String.ownerRecordField, refs)
            let datePredicate = NSPredicate(format: "creationDate >= %@ && creationDate <= %@", from, to)
            let predicate = NSCompoundPredicate(type: .and, subpredicates: [refPredicate, datePredicate])
            let query = CKQuery(recordType: .postsRecordType, predicate: predicate)
            
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query) { completion in
                switch completion {
                case .success(let results):
                    var postModels: [PostModel] = []
                    for result in results.matchResults {
                        switch result.1 {
                        case .success(let postRecord):
                            if let imageAsset = postRecord[.imageRecordField] as? CKAsset,
                               let owner = postRecord[.ownerRecordField] as? CKRecord.Reference,
                               let imageURL = imageAsset.fileURL,
                               let data = try? Data(contentsOf: imageURL),
                               let image = UIImage(data: data) {
                                postModels.append(PostModel(id: postRecord.recordID, ownerId: owner.recordID, photo: image, creationDate: postRecord.creationDate ?? .now))
                            }
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                            return
                        }
                    }
                    continuation.resume(returning: .success(postModels.sorted(by: { $0.creationDate > $1.creationDate })))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func addPostForUserWith(_ id: CKRecord.ID, image: UIImage) async -> Result<PostModel, Error> {
        await withCheckedContinuation { continuation in
            let newPost = CKRecord(recordType: .postsRecordType)
            let owner = CKRecord.Reference.init(recordID: id, action: .deleteSelf)
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
                                    continuation.resume(returning: .success(PostModel(id: returnedPost.recordID, ownerId: owner.recordID, photo: image, creationDate: returnedPost.creationDate ?? .now)))
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}

