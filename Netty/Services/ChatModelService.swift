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
    
    func getChatsIDsListForUser(with id: CKRecord.ID) async -> Result<[CKRecord.ID], Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedUserRecord, error in
                if let user = returnedUserRecord,
                   let chatsRefsList = user[.chatsRecordField] as? [CKRecord.Reference] {
                    
                    if chatsRefsList.isEmpty {
                        continuation.resume(returning: .success([]))
                    } else {
                        let chatsIDsList = chatsRefsList.map { $0.recordID }
                        continuation.resume(returning: .success(chatsIDsList))
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

    func downloadChatModel(for record: CKRecord, currentUserId: CKRecord.ID) async -> Result<ChatModel, Error> {
    await withCheckedContinuation { continuation in
        if let participantsArray = record[.participantsRecordField] as? [CKRecord.Reference],
            let otherParticipant = participantsArray.first(where: { $0.recordID != currentUserId }) {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: otherParticipant.recordID) { returnedRecord, error in
                
                if let record = returnedRecord,
                    let nickname = record[.nicknameRecordField] as? String {
                    var avatar: UIImage? = nil
                    
                    if let imageAsset = record[.avatarRecordField] as? CKAsset,
                        let imageURL = imageAsset.fileURL,
                        let data = try? Data(contentsOf: imageURL),
                        let image = UIImage(data: data) {
                        avatar = image
                    }
                    
                    continuation.resume(returning: .success(ChatModel(id: otherParticipant.recordID, userName: nickname, profileImage: avatar, lastMessage: nil)))
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
}
