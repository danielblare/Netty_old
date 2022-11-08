//
//  UserModel.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import Foundation
import CloudKit


enum UserModelDestination {
    case chat, profile
}


struct UserModel: Identifiable, Equatable, Hashable {
    let id: CKRecord.ID
    let firstName, lastName, nickname: String
    
}

struct UserModelHolder: Hashable {
    let destination: UserModelDestination
    let userModel: UserModel
}

class RecentUsersHolder {
    
    let users: [UserModel]
    
    init(_ users: [UserModel]) {
        self.users = users
    }
}

