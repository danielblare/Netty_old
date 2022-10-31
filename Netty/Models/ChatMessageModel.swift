//
//  ChatMessageModel.swift
//  Netty
//
//  Created by Danny on 10/31/22.
//

import Foundation


struct ChatMessageModel: Identifiable {
    let id = UUID()
    let message: String
    let isCurrentUser: Bool
   
}
