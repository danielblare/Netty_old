//
//  ChatViewModel.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI
import CloudKit

final class ChatViewModel: ObservableObject {
    
    // Message text field
    @Published var messageTextField: String = ""
    
    // Messages array
    @Published var chatMessages: [ChatMessageModel] = []
    
    // Shows loading view if true
    @Published var isLoading: Bool = true
    
    // Current user's ID
    let ownId: CKRecord.ID
    private var chatId: CKRecord.ID? = nil
    
    // Pal's model
    let userModel: UserModel
    
    // Alert
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    init(user: UserModel, ownId: CKRecord.ID) {
        userModel = user
        self.ownId = ownId
        
        Task {
            await getChat(participants: (.init(recordID: ownId, action: .none), .init(recordID: userModel.id, action: .none)))
        }
    }
    
    func sendMessage() async {
        guard let chatId = chatId else { return }
        if !messageTextField.isEmpty {
            let message = ChatMessageModel(userId: ownId.recordName, message: messageTextField, date: .now)
            if let data = try? JSONEncoder().encode(message) {
                switch await ChatModelService.instance.sendMessage(data, in: chatId, ownId: ownId) {
                case .success(let returnedRecord):
                    if returnedRecord != nil {
                        await MainActor.run {
                            withAnimation {
                                messageTextField = ""
                                chatMessages.append(message)
                            }
                        }
                    } else {
                        showAlert(title: "Error sending message", message: "Error while saving new data to database")
                    }
                case .failure(let error):
                    showAlert(title: "Error sending message", message: error.localizedDescription)
                }
            } else {
                showAlert(title: "Error sending message", message: "Error while encoding message")
            }
        }
    }
    
    
    private func getChat(participants: (CKRecord.Reference, CKRecord.Reference)) async {
        switch await ChatModelService.instance.doesChatExistWith(participants: participants) {
        case .success(let returnedRecordId):
            if let recordId = returnedRecordId {
                chatId = recordId
                switch await ChatModelService.instance.getMessageModels(forChatWith: recordId) {
                case .success(let chatModels):
                    await MainActor.run {
                        chatMessages = chatModels
                        isLoading = false
                    }
                case .failure(let error):
                    showAlert(title: "Error while fetching messages", message: error.localizedDescription)
                }
            } else {
                #warning("set chat ID")
                //Create new chat
            }
        case .failure(let error):
            showAlert(title: "Error while fetching chat", message: error.localizedDescription)
        }
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
