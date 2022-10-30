//
//  ChatViewModel.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import Foundation
import CloudKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
}

final class ChatViewModel: ObservableObject {
    
    @Published var messageTextField: String = ""
    @Published var chatMessages: [ChatMessage]? = nil
    @Published var isLoading: Bool = true
    
    private let ownId: CKRecord.ID?
    let userModel: FindUserModel
    
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
        
    
    init(user: FindUserModel, ownId: CKRecord.ID?) {
        userModel = user
        self.ownId = ownId
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
}
