//
//  ChatMessageModel.swift
//  Netty
//
//  Created by Danny on 10/31/22.
//

import Foundation
import CloudKit

struct ChatMessageModel: Identifiable, Codable, Equatable {
    var id = UUID()
    let userId, message: String
    let date: Date
   
    func isCurrentUser(ownId: CKRecord.ID) -> Bool {
        ownId.recordName == userId
    }
}

class ChatMessagesHolder {
    
    let messages: [ChatMessageModel]
    
    init(_ messages: [ChatMessageModel]) {
        self.messages = messages
    }
}
