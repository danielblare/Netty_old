//
//  UserInfoService.swift
//  Netty
//
//  Created by Danny on 9/11/22.
//

import Foundation
import SwiftUI
import CloudKit

actor UserInfoService {
    
    
    static let instance = UserInfoService()
    
    private init() {}
    
    enum CustomError: Error {
        case dataError
    }
    
    func follow(_ user: UserModel, ownId: CKRecord.ID) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: ownId) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let ownUser = returnedRecord {
                    CKContainer.default().publicCloudDatabase.fetch(withRecordID: user.id) { returnedRecord, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else if let userToFollow = returnedRecord {
                            
                            var following = ownUser[.followingRecordField] as? [CKRecord.Reference] ?? []
                            var followers = userToFollow[.followersRecordField] as? [CKRecord.Reference] ?? []
                            let oldUser = ownUser
                            following.insert(CKRecord.Reference(record: userToFollow, action: .none), at: 0)
                            followers.insert(CKRecord.Reference(record: ownUser, action: .none), at: 0)
                            ownUser[.followingRecordField] = following
                            userToFollow[.followersRecordField] = followers
                            
                            CKContainer.default().publicCloudDatabase.save(ownUser) { returnedRecord, error in
                                if let error = error {
                                    continuation.resume(returning: .failure(error))
                                } else if returnedRecord != nil {
                                    
                                    CKContainer.default().publicCloudDatabase.save(userToFollow) { returnedRecord, error in
                                        if returnedRecord != nil {
                                            continuation.resume(returning: .success(()))
                                        } else {
                                            CKContainer.default().publicCloudDatabase.save(oldUser) { _, _ in }
                                            
                                            if let error = error {
                                                continuation.resume(returning: .failure(error))
                                            } else {
                                                continuation.resume(returning: .failure(CustomError.dataError))
                                            }
                                        }
                                    }
                                    
                                } else {
                                    continuation.resume(returning: .failure(CustomError.dataError))
                                }
                            }
                        } else {
                            continuation.resume(returning: .failure(CustomError.dataError))
                        }
                    }
                    
                } else {
                    continuation.resume(returning: .failure(CustomError.dataError))
                }
            }
        }
    }
    
    func unfollow(_ user: UserModel, ownId: CKRecord.ID) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: ownId) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let ownUser = returnedRecord {
                    CKContainer.default().publicCloudDatabase.fetch(withRecordID: user.id) { returnedRecord, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else if let userToFollow = returnedRecord {
                            
                            if var following = ownUser[.followingRecordField] as? [CKRecord.Reference],
                               var followers = userToFollow[.followersRecordField] as? [CKRecord.Reference] {
                                let oldUser = ownUser
                                following.removeAll(where: { $0.recordID == user.id })
                                followers.removeAll(where: { $0.recordID == ownId })
                                ownUser[.followingRecordField] = following
                                userToFollow[.followersRecordField] = followers
                                
                                CKContainer.default().publicCloudDatabase.save(ownUser) { returnedRecord, error in
                                    if let error = error {
                                        continuation.resume(returning: .failure(error))
                                    } else if returnedRecord != nil {
                                        
                                        CKContainer.default().publicCloudDatabase.save(userToFollow) { returnedRecord, error in
                                            if returnedRecord != nil {
                                                continuation.resume(returning: .success(()))
                                            } else {
                                                CKContainer.default().publicCloudDatabase.save(oldUser) { _, _ in }
                                                
                                                if let error = error {
                                                    continuation.resume(returning: .failure(error))
                                                } else {
                                                    continuation.resume(returning: .failure(CustomError.dataError))
                                                }
                                            }
                                        }
                                        
                                    } else {
                                        continuation.resume(returning: .failure(CustomError.dataError))
                                    }
                                }
                            } else {
                                continuation.resume(returning: .failure(CustomError.dataError))
                            }
                        } else {
                            continuation.resume(returning: .failure(CustomError.dataError))
                        }
                    }
                    
                } else {
                    continuation.resume(returning: .failure(CustomError.dataError))
                }
            }
        }
    }
    
    
    func fetchUserDataForUser(with id: CKRecord.ID) async -> Result<UserModel, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedUser, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let user = returnedUser,
                          let firstName = user[.firstNameRecordField] as? String,
                          let lastName = user[.lastNameRecordField] as? String,
                          let nickname = user[.nicknameRecordField] as? String {
                    let followers = user[.followersRecordField] as? [CKRecord.Reference] ?? []
                    let following = user[.followingRecordField] as? [CKRecord.Reference] ?? []
                    continuation.resume(returning: .success(UserModel(id: user.recordID, firstName: firstName, lastName: lastName, nickname: nickname, followers: followers, following: following)))
                } else {
                    continuation.resume(returning: .failure(CustomError.dataError))
                }
            }
        }
    }
    
    func fetchUserDataForUsers(with ids: [CKRecord.ID]) async -> Result<[UserModel], Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordIDs: ids) { result in
                switch result {
                case .success(let dictionary):
                    var resultArray: [UserModel] = []
                    for result in dictionary {
                        switch result.value {
                        case .success(let user):
                            if let firstName = user[.firstNameRecordField] as? String,
                               let lastName = user[.lastNameRecordField] as? String,
                               let nickname = user[.nicknameRecordField] as? String {
                                let followers = user[.followersRecordField] as? [CKRecord.Reference] ?? []
                                let following = user[.followingRecordField] as? [CKRecord.Reference] ?? []
                                resultArray.append(UserModel(id: user.recordID, firstName: firstName, lastName: lastName, nickname: nickname, followers: followers, following: following))
                            } else {
                                continuation.resume(returning: .failure(CustomError.dataError))
                                return
                            }
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                            return
                        }
                    }
                    continuation.resume(returning: .success(resultArray))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    
    func fetchNicknameForUser(with id: CKRecord.ID) async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedRecord, error in
                if let returnedRecord = returnedRecord {
                    if let nickname = returnedRecord[.nicknameRecordField] as? String {
                        continuation.resume(returning: .success(nickname))
                    } else {
                        continuation.resume(returning: .failure(CustomError.dataError))
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func updateNicknameForUserWith(recordId: CKRecord.ID, newNickname: String) async -> Result<CKRecord, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordId) { returnedRecord, error in
                if let record = returnedRecord {
                    record[.nicknameRecordField] = newNickname
                    CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                        if let record = returnedRecord {
                            continuation.resume(returning: .success(record))
                        } else if let error = error {
                            continuation.resume(returning: .failure(error))
                        }
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
