//
//  DirectViewModel.swift
//  Netty
//
//  Created by Danny on 9/14/22.
//

import Foundation
import SwiftUI
import CloudKit
import Combine

@MainActor
class DirectViewModel: ObservableObject {
    
    @Published var chatsArray: [ChatModel] = []
    @Published var isLoading: Bool = false
    
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    private var userRecordId: CKRecord.ID?
    
    
    init(userRecordId: CKRecord.ID?) {
        self.userRecordId = userRecordId
        Task {
            await sync()
        }
    }
    
    func sync() async {
        await MainActor.run(body: {
            withAnimation {
                chatsArray = []
                isLoading = true
            }
        })
        if let id = userRecordId {
            switch await dataService.getChatsIDsListForUser(with: id) {
            case .success(let IDs):
                switch await dataService.getChats(with: IDs) {
                case .success(let chats):
                    var result: [ChatModel] = []
                    for chat in chats {
                        switch chat.value {
                        case .success(let record):
                            switch await dataService.downloadChatModel(for: record, currentUserId: id) {
                            case .success(let chatModel):
                                result.append(chatModel)
                            case .failure(let error):
                                showAlert(title: "Error while getting chat model", message: error.localizedDescription)
                            }
                        case .failure(let error):
                            showAlert(title: "Error while getting chats", message: error.localizedDescription)
                        }
                    }
                    await MainActor.run(body: {
                        withAnimation {
                            chatsArray = result
                        }
                    })
                case .failure(let error):
                    showAlert(title: "Error while getting chats", message: error.localizedDescription)
                }
            case .failure(let failure):
                showAlert(title: "Error while getting chats IDs", message: failure.localizedDescription)
            }
        }
        await MainActor.run(body: {
            withAnimation {
                isLoading = false
            }
        })
    }
        
    private let dataService = ChatModelService.instance
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
}


