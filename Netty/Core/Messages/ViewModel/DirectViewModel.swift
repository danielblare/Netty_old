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
    
    // User's chats array
    @Published var chatsArray: [ChatRowModel] = []
    
    // Shows loading view if true
    @Published var isLoading: Bool = true
    
    // Rotates refreshing arrow if true
    @Published var isRefreshing: Bool = false
    
    // Alert
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    // Current user's record ID
    let userId: CKRecord.ID
    
    // Chat data service
    private let dataService = ChatModelService.instance
    
    init(userId: CKRecord.ID) {
        self.userId = userId
        Task {
            isLoading = true
            await sync()
            isLoading = false
        }
        requestNotificationPermission()
    }
    
    /// Syncs chats
    func sync() async {
        await downloadData()
    }
    
    /// Deletes chat
    func delete(chat: ChatRowModel) async {
        let backup = chatsArray.first(where: { $0.id == chat.id }) // Saves chat before deleting
        chatsArray.removeAll(where: { $0.id == chat.id }) // Removes chat from array
        switch await dataService.deleteChat(with: chat.id, for: userId) { // Deletes chat in database
        case .success(_):
            break
        case .failure(let error):
            if let backup = backup { // If failure restores chat from backup
                chatsArray.append(backup)
            }
            showAlert(title: "Error while deleting chat", message: error.localizedDescription)
        }
    }
    
    /// Requests permission to send notifications
    private func requestNotificationPermission() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                print(error)
            } else if success {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Downloads user's chats
    private func downloadData() async {
            await MainActor.run(body: {
                withAnimation {
                    isRefreshing = true
                }
            })
            switch await dataService.getChatsIDsListForUser(with: userId) { // Gets IDs for all chats of current user
            case .success(let IDs):
                switch await dataService.getChats(with: IDs) { // Fetches chats from IDs
                case .success(let chats):
                    var result: [ChatRowModel] = []
                    for chat in chats {
                        switch chat.value {
                        case .success(let record):
                            switch await dataService.downloadChatModel(for: record, currentUserId: userId, chatId: chat.key, modificationDate: record.modificationDate) { // Downloads chat models
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
                            chatsArray = result.sorted { f, s in // Sorts chats
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
        await MainActor.run(body: {
            withAnimation {
                isRefreshing = false
            }
        })
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


