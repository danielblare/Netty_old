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
    @Published var isLoading: Bool = true
    @Published var isRefreshing: Bool = false
    
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    let userRecordId: CKRecord.ID?
    
    
    init(userRecordId: CKRecord.ID?) {
        self.userRecordId = userRecordId
        Task {
            isLoading = true
            await sync()
            isLoading = false
        }
    }
    
    func sync() async {
        await downloadData()
    }
    
    func delete(chat: ChatModel) async {
        if let id = userRecordId {
            let backup = chatsArray.first(where: { $0.id == chat.id })
            chatsArray.removeAll(where: { $0.id == chat.id })
            switch await dataService.deleteChat(with: chat.id, for: id) {
            case .success(_):
                break
            case .failure(let error):
                if let backup = backup {
                    chatsArray.append(backup)
                }
                showAlert(title: "Error while deleting chat", message: error.localizedDescription)
            }
        }
    }
    
    private func downloadData() async {
        if let id = userRecordId {
            await MainActor.run(body: {
                withAnimation {
                    isRefreshing = true
                }
            })
            switch await dataService.getChatsIDsListForUser(with: id) {
            case .success(let IDs):
                switch await dataService.getChats(with: IDs) {
                case .success(let chats):
                    var result: [ChatModel] = []
                    for chat in chats {
                        switch chat.value {
                        case .success(let record):
                            switch await dataService.downloadChatModel(for: record, currentUserId: id, chatId: chat.key, modificationDate: record.modificationDate) {
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
                            chatsArray = result.sorted { f, s in
                                if let fdate = f.modificationDate,
                                   let sdate = s.modificationDate {
                                    return fdate > sdate
                                } else {
                                    return false
                                }
                            }
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
                isRefreshing = false
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


