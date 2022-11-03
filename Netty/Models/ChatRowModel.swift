//
//  ChatRowModel.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import CloudKit
import SwiftUI


struct ChatRowModel: Identifiable {
    let id: CKRecord.ID
    let user: UserModel
    let lastMessage: String?
    let modificationDate: Date?
}
