//
//  ChatModelService.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import CloudKit
import SwiftUI

actor ChatModelService {
    static let instance = ChatModelService()
    
    private init() {}
    
    enum CustomError: Error {
        case userHaveNoChats
        case cantGetChatsListFromDatabase
    }
    
    func deleteChat(with chatId: CKRecord.ID, for userId: CKRecord.ID) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: userId) { returnedUserRecord, error in
                if let user = returnedUserRecord {
                    if let chatsRefsList = user[.chatsRecordField] as? [CKRecord.Reference]? {
                        if var chatsRefsList = chatsRefsList {
                            chatsRefsList.removeAll(where: { $0.recordID == chatId })
                            user[.chatsRecordField] = chatsRefsList
                            CKContainer.default().publicCloudDatabase.save(user) { _, error in
                                if let error = error {
                                    continuation.resume(returning: .failure(error))
                                } else {
                                    continuation.resume(returning: .success(()))
                                }
                            }
                        } else {
                            continuation.resume(returning: .failure(CustomError.userHaveNoChats))
                        }
                    } else {
                        continuation.resume(returning: .failure(CustomError.cantGetChatsListFromDatabase))
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func sendMessage(_ data: Data, in chatId: CKRecord.ID, ownId: CKRecord.ID, palsId: CKRecord.ID) async -> Result<CKRecord?, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: chatId) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let chatRecord = returnedRecord {
                    if var messages = chatRecord[.messagesRecordField] as? [Data] {
                        messages.append(data)
                        chatRecord[.messagesRecordField] = messages
                        
                    } else {
                        chatRecord[.messagesRecordField] = [data]
                    }
                    
                    CKContainer.default().publicCloudDatabase.save(chatRecord) { returnedRecord, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else if let record = returnedRecord {
                            Task {
                                switch await self.addChatToUsersListIfNeeded(chatId, userId: ownId) {
                                case .success(_):
                                    break
                                case .failure(let error):
                                    continuation.resume(returning: .failure(error))
                                }
                                
                                switch await self.addChatToUsersListIfNeeded(chatId, userId: palsId) {
                                case .success(_):
                                    break
                                case .failure(let error):
                                    continuation.resume(returning: .failure(error))
                                }
                                
                                continuation.resume(returning: .success(record))
                            }
                        }
                    }
                } else {
                    continuation.resume(returning: .success(nil))
                }
            }
        }
    }
    
    func createNewChatFor(_ participants: (CKRecord.Reference, CKRecord.Reference), ownId: CKRecord.ID, palsId: CKRecord.ID) async -> Result<CKRecord, Error> {
        await withCheckedContinuation { continuation in
            let newChat = CKRecord(recordType: .chatsRecordType)
            newChat[.participantsRecordField] = [participants.0, participants.1]
            CKContainer.default().publicCloudDatabase.save(newChat) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let record = returnedRecord {
                    Task {
                        switch await self.addChatToUsersListIfNeeded(record.recordID, userId: ownId) {
                        case .success(_):
                            break
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                        }
                        switch await self.addChatToUsersListIfNeeded(record.recordID, userId: palsId) {
                        case .success(_):
                            break
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                        }
                        continuation.resume(returning: .success(record))
                    }
                }
            }
        }
    }
    
    private func addChatToUsersListIfNeeded(_ chatId: CKRecord.ID, userId: CKRecord.ID) async -> Result<CKRecord, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: userId) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let record = returnedRecord {
                    if var chats = record[.chatsRecordField] as? [CKRecord.Reference] {
                        if chats.contains(CKRecord.Reference(recordID: chatId, action: .none)) {
                            continuation.resume(returning: .success(record))
                        } else {
                            chats.append(CKRecord.Reference(recordID: chatId, action: .none))
                            record[.chatsRecordField] = chats
                            CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                                if let error = error {
                                    continuation.resume(returning: .failure(error))
                                } else if let record = returnedRecord {
                                    continuation.resume(returning: .success(record))
                                }
                            }

                        }
                    } else {
                        record[.chatsRecordField] = [CKRecord.Reference(recordID: chatId, action: .none)]
                        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                            if let error = error {
                                continuation.resume(returning: .failure(error))
                            } else if let record = returnedRecord {
                                continuation.resume(returning: .success(record))
                            }
                        }

                    }
                }
            }
        }
    }
    func getMessageModels(forChatWith id: CKRecord.ID) async -> Result<[ChatMessageModel], Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let chatRecord = returnedRecord,
                          let messagesDataArray = chatRecord[.messagesRecordField] as? [Data] {
                    do {
                        continuation.resume(returning: .success(try messagesDataArray.map({ try JSONDecoder().decode(ChatMessageModel.self, from: $0) })))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                } else {
                    continuation.resume(returning: .success([]))
                }
            }
        }
    }
    
    func doesChatExistWith(participants: (CKRecord.Reference, CKRecord.Reference)) async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            let predicate1 = NSPredicate(format: "\(String.participantsRecordField) CONTAINS %@", participants.0)
            let predicate2 = NSPredicate(format: "\(String.participantsRecordField) CONTAINS %@", participants.1)
            let predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2])
            let query = CKQuery(recordType: .chatsRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    continuation.resume(returning: .success(success.matchResults.first?.0))
                case .failure(let failure):
                    continuation.resume(returning: .failure(failure))
                }
            }
        }
    }

    
    func getChatsIDsListForUser(with id: CKRecord.ID) async -> Result<[CKRecord.ID], Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedUserRecord, error in
                if let user = returnedUserRecord {
                    if let chatsRefsList = user[.chatsRecordField] as? [CKRecord.Reference]? {
                        if let list = chatsRefsList {
                            let chatsIDsList = list.map { $0.recordID }
                            continuation.resume(returning: .success(chatsIDsList))
                        } else {
                            continuation.resume(returning: .success([]))
                        }
                    } else {
                        continuation.resume(returning: .failure(CustomError.cantGetChatsListFromDatabase))
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func getChats(with IDs: [CKRecord.ID]) async -> Result<([CKRecord.ID : Result<CKRecord, Error>]), Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordIDs: IDs) { result in
                switch result {
                case .success(let chats):
                    continuation.resume(returning: .success(chats))
                case .failure(let failure):
                    continuation.resume(returning: .failure(failure))
                }
            }
        }
    }
    
    func downloadChatModel(for chatRecord: CKRecord, currentUserId: CKRecord.ID, modificationDate: Date?) async -> Result<ChatRowModel, Error> {
        await withCheckedContinuation { continuation in
            if let participantsArray = chatRecord[.participantsRecordField] as? [CKRecord.Reference],
               let otherParticipant = participantsArray.first(where: { $0.recordID != currentUserId }) {
                CKContainer.default().publicCloudDatabase.fetch(withRecordID: otherParticipant.recordID) { returnedRecord, error in
                    
                    if let record = returnedRecord,
                       let firstName = record[.firstNameRecordField] as? String,
                       let lastName = record[.lastNameRecordField] as? String,
                       let nickname = record[.nicknameRecordField] as? String {
                        var lastMessage: String? = nil
                        if let messages = chatRecord[.messagesRecordField] as? [Data],
                           let lastData = messages.last,
                           let messageModel = try? JSONDecoder().decode(ChatMessageModel.self, from: lastData) {
                            lastMessage = "\(messageModel.isCurrentUser(ownId: currentUserId) ? "You" : "\(nickname)"): \(messageModel.message)"
                        }
                        continuation.resume(returning: .success(ChatRowModel(id: chatRecord.recordID, user: UserModel(id: record.recordID, firstName: firstName, lastName: lastName, nickname: nickname), lastMessage: lastMessage, modificationDate: modificationDate)))
                        
                    } else if let error = error {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
}
