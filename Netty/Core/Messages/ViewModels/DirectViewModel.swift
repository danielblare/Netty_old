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
    @Published var isLoading: Bool = false
        
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
            await sync()
        }
        requestNotificationPermission()
        subscribeToNotifications()
    }
    
    
    private func subscribeToNotifications() {
                
        guard !UserDefaults.standard.bool(forKey: "didCreateQuerySubscription") else { return }
        
        let predicate = NSPredicate(format: "\(String.participantsRecordField) CONTAINS %@", CKRecord.Reference(recordID: userId, action: .none))
        
        let subscription = CKQuerySubscription(recordType: .chatsRecordType, predicate: predicate, subscriptionID: "\(userId)_new_message", options: .firesOnRecordUpdate)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.title = "New message"
        notificationInfo.alertBody = "Open the app to check new message"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
                
            
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { subscription, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                UserDefaults.standard.setValue(true, forKey: "didCreateQuerySubscription")
            }
        }
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
            cacheManager.addTo(cacheManager.chatRows, key: userId.recordName, value: ChatRowModelsHolder(chatsArray))
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
    
    private let cacheManager = CacheManager.instance
    #warning("Feed")
    
    #warning("washing machine")
    
    /// Downloads user's chats
    private func downloadData() async {
        
        if let savedChatRows = cacheManager.getFrom(cacheManager.chatRows, key: userId.recordName) {
            await MainActor.run {
                if savedChatRows.rows != chatsArray {
                    withAnimation {
                        chatsArray = savedChatRows.rows
                    }
                }
            }
            switch await dataService.getChatsForUserWith(userId) {
            case .success(let chats):
                if chats != chatsArray {
                    cacheManager.addTo(cacheManager.chatRows, key: userId.recordName, value: ChatRowModelsHolder(chats))
                    await MainActor.run {
                        chatsArray = chats
                    }
                }
            case .failure(_):
                break
            }
        } else {
            await MainActor.run {
                isLoading = true
            }
            switch await dataService.getChatsForUserWith(userId) {
            case .success(let chats):
                cacheManager.addTo(cacheManager.chatRows, key: userId.recordName, value: ChatRowModelsHolder(chats))
                await MainActor.run {
                    chatsArray = chats
                    withAnimation {
                        isLoading = false
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    isLoading = false
                }
                showAlert(title: "Error while fetching chats", message: error.localizedDescription)
            }
        }
        
        
            
    }
    
    /// Shows alert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
}


