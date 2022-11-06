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
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    
    // Current user's ID
    let ownId: CKRecord.ID
    private var chatId: CKRecord.ID? = nil
    
    // Pal's model
    let userModel: UserModel
    
    private var participants: (CKRecord.Reference, CKRecord.Reference) {
        (.init(recordID: ownId, action: .none), .init(recordID: userModel.id, action: .none))
    }
    
    private let cacheManager = CacheManager.instance
    
    // Alert
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    init(user: UserModel, ownId: CKRecord.ID) {
        userModel = user
        self.ownId = ownId
        
        Task {
            await getChat()
        }
    }
    
    func sendMessage() async {
        if !messageTextField.isEmpty {
            await MainActor.run {
                isSending = true
            }
            if chatId == nil {
                switch await ChatModelService.instance.createNewChatFor(participants, ownId: ownId, palsId: userModel.id) {
                case .success(let record):
                    chatId = record.recordID
                case .failure(let error):
                    showAlert(title: "Error creating new chat", message: error.localizedDescription)
                }
            }
            guard let chatId = chatId else { return }
            let message = ChatMessageModel(userId: ownId.recordName, message: messageTextField, date: .now)
            if let data = try? JSONEncoder().encode(message) {
                switch await ChatModelService.instance.sendMessage(data, in: chatId, ownId: ownId, palsId: userModel.id) {
                case .success(let returnedRecord):
                    if returnedRecord != nil {
                        await MainActor.run {
                            withAnimation {
                                messageTextField = ""
                                isSending = false
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
    
    
    private func getChat() async {
        switch await ChatModelService.instance.doesChatExistWith(participants: participants) {
        case .success(let returnedRecordId):
            if let recordId = returnedRecordId {
                chatId = recordId
                if let savedMessages = cacheManager.getFrom(cacheManager.chatMessages, key: "\(recordId.recordName)_messages") {
                    await MainActor.run {
                        withAnimation {
                            chatMessages = savedMessages.messages
                        }
                    }
                    switch await ChatModelService.instance.getMessageModels(forChatWith: recordId) {
                    case .success(let dataArray):
                        if savedMessages.messages != dataArray {
                            cacheManager.addTo(cacheManager.chatMessages, key: "\(recordId.recordName)_messages", value: ChatMessagesHolder(dataArray))
                            await MainActor.run(body: {
                                withAnimation {
                                    chatMessages = dataArray
                                }
                            })
                        }
                    case .failure(_):
                        break
                    }
                } else {
                    await MainActor.run {
                        isLoading = true
                    }
                    switch await ChatModelService.instance.getMessageModels(forChatWith: recordId) {
                    case .success(let chatModels):
                        cacheManager.addTo(cacheManager.chatMessages, key: "\(recordId.recordName)_messages", value: ChatMessagesHolder(chatModels))
                        await MainActor.run {
                            isLoading = false
                            withAnimation {
                                chatMessages = chatModels
                            }
                        }
                    case .failure(let error):
                        showAlert(title: "Error while fetching messages", message: error.localizedDescription)
                    }
                }
                
            } else {
                chatId = nil
                await MainActor.run {
                    chatMessages = []
                    isLoading = false
                }
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
