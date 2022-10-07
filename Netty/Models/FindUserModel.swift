//
//  FindUserModel.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import Foundation
import CloudKit

struct FindUserModel: Identifiable, Equatable {
    let id: CKRecord.ID
    let firstName, lastName, nickname: String
    
}

class RecentUsersHolder {
    
    let users: [FindUserModel]
    
    init(_ users: [FindUserModel]) {
        self.users = users
    }
}
