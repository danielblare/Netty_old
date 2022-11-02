//
//  ChatModelService.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import CloudKit
import SwiftUI

class ChatModelService {
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
    
    func sendMessage(_ data: Data, in chat: CKRecord.ID) async -> Result<CKRecord?, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: chat) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let chatRecord = returnedRecord,
                          let messages = chatRecord[.messagesRecordField] as? [NSData] {
                    print("2 \(messages)")
                    var newMessages = messages
                    newMessages.append(NSData(data: data))
                    print("2 \(newMessages)")
                    chatRecord[.messagesRecordField] = newMessages
                    CKContainer.default().publicCloudDatabase.save(chatRecord) { returnedRecord, error in
                        if let error = error {
                            continuation.resume(returning: .failure(error))
                        } else if let record = returnedRecord {
                            continuation.resume(returning: .success(record))
                        }
                    }
                } else {
                    continuation.resume(returning: .success(nil))
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
                          let messagesDataArray = chatRecord[.messagesRecordField] as? [NSData] {
                    do {
                        continuation.resume(returning: .success(try messagesDataArray.map({ try JSONDecoder().decode(ChatMessageModel.self, from: Data(referencing: $0)) })))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                } else {
                    continuation.resume(returning: .success([]))
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

    func downloadChatModel(for record: CKRecord, currentUserId: CKRecord.ID, chatId: CKRecord.ID, modificationDate: Date?) async -> Result<ChatRowModel, Error> {
    await withCheckedContinuation { continuation in
        if let participantsArray = record[.participantsRecordField] as? [CKRecord.Reference],
            let otherParticipant = participantsArray.first(where: { $0.recordID != currentUserId }) {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: otherParticipant.recordID) { returnedRecord, error in
                
                if let record = returnedRecord,
                    let nickname = record[.nicknameRecordField] as? String {
                    
                    continuation.resume(returning: .success(ChatRowModel(id: chatId, opponentId: otherParticipant.recordID, userName: nickname, lastMessage: nil, modificationDate: modificationDate)))
                    
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
}
