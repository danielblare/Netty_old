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

enum RefDestination {
    case following, followers
}


struct UserModel: Identifiable, Equatable, Hashable {
    let id: CKRecord.ID
    let firstName, lastName, nickname: String
    let followers, following: [CKRecord.Reference]
}

class UserModelHolder {
    let user: UserModel
    
    init(_ user: UserModel) {
        self.user = user
    }
}

struct RefsHolderWithDestination: Hashable {
    let destination: RefDestination
    let refs: [CKRecord.Reference]
}

struct UserModelHolderWithDestination: Hashable {
    let destination: UserModelDestination
    let userModel: UserModel
}

class RecentUsersHolder {
    
    let users: [UserModel]
    
    init(_ users: [UserModel]) {
        self.users = users
    }
}

