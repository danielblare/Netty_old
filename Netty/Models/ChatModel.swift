//
//  ChatModel.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import CloudKit
import SwiftUI


struct ChatModel: Identifiable {
    var id: CKRecord.ID
    let opponentId: CKRecord.ID
    
    let userName: String
    let lastMessage: String?
}
