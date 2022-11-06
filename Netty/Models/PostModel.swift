//
//  PostModel.swift
//  Netty
//
//  Created by Danny on 11/6/22.
//

import SwiftUI
import CloudKit

struct PostModel: Identifiable, Equatable, Hashable {
    let id, ownerId: CKRecord.ID
    let photo: UIImage
    let creationDate: Date
}

class PostModelsHolder {
    
    let posts: [PostModel]
    
    init(_ posts: [PostModel]) {
        self.posts = posts
    }
}
