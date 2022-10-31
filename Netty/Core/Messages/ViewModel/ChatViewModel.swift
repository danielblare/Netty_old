//
//  ChatViewModel.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import Foundation
import CloudKit

final class ChatViewModel: ObservableObject {
    
    // Message text field
    @Published var messageTextField: String = ""
    
    // Messages array
    @Published var chatMessages: [ChatMessageModel]? = nil
    
    // Shows loading view if true
    @Published var isLoading: Bool = true
    
    // Current user's ID
    private let ownId: CKRecord.ID?
    
    // Pal's model
    let userModel: UserModel
    
    // Alert
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    init(user: UserModel, ownId: CKRecord.ID?) {
        userModel = user
        self.ownId = ownId
    }
    
    
    
    
    
    
    
    
    
    
    /// Shows alert
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
}
