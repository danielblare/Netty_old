//
//  ChatMessageModel.swift
//  Netty
//
//  Created by Danny on 10/31/22.
//

import Foundation
import CloudKit

struct ChatMessageModel: Identifiable, Codable {
    let id, message: String
    let date: Date
   
    func isCurrentUser(ownId: CKRecord.ID) -> Bool {
        ownId.recordName == id
    }
}
