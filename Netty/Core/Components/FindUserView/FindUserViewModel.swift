//
//  FindUserViewModel.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import Foundation
import SwiftUI
import CloudKit

class FindUserViewModel: ObservableObject {
    
    // Recent users array
    @Published var recentsArray: [UserModel] = []
    
    // Results of search through users
    @Published var foundArray: [UserModel] = []
    
    // Shows loading view if true
    @Published var isLoading: Bool = false
    
    // Search text field
    @Published var searchText: String = ""
    
    // Shows recents if true
    @Published var showRecents: Bool = false
    
    // Shows search results if true
    @Published var showFound: Bool = false
    
    // Current user id
    private let userId: CKRecord.ID
    
    // Alert
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    // Find user data service
    private let dataService = FindUserModelService.instance
    // Cache manager
    private let cacheManager = CacheManager.instance
    
    // Search task
    private var searchTask: Task<(), Never>?
    
    init(id: CKRecord.ID) {
        self.userId = id
        Task {
            await getResents()
        }
    }
    
    /// Clears all recent users
    func clearRecents() async {
        switch await CloudKitManager.instance.updateFieldForUserWith(recordId: userId, field: .recentUsersInSearchRecordField, newData: [CKRecord.Reference]()) {
        case .success(_):
            await MainActor.run {
                withAnimation {
                    recentsArray = []
                    cacheManager.delete(from: cacheManager.recentUsers, "users", for: "") // Clears cache
                }
            }
        case .failure(let error):
            showAlert(title: "Error while deleting recents", message: error.localizedDescription)
        }
        
    }
    
    /// Performs some actions if search text field was changed
    func searchTextChanged() {
        searchTask?.cancel()
        isLoading = false
        if searchText.isEmpty {
            Task {
                await getResents()
            }
        } else {
            showRecents = false
        }
        
        showFound = false
    }
    
    /// Performs actions if search process started
    func executeQuery() async {
        if !searchText.isEmpty {
            searchTask = Task {
                await MainActor.run {
                    isLoading = true
                }
                switch await dataService.downloadSearching(searchText, id: userId) {
                case .success(let resultArray):
                    if let task = searchTask, !task.isCancelled {
                        await MainActor.run {
                            isLoading = false
                            foundArray = resultArray
                            showFound = true
                        }
                    }
                case .failure(let error):
                    await MainActor.run {
                        isLoading = false
                    }
                    showAlert(title: "Error while searching", message: error.localizedDescription)
                }
            }
        }
    }
    
    /// Gets recents from database
    private func getResents() async {
        if let savedRecents = cacheManager.getFrom(cacheManager.recentUsers, key: "users") { // Checks if there are any recents in cache
            await MainActor.run {
                withAnimation {
                    recentsArray = savedRecents.users
                    showRecents = true
                }
            }
            switch await dataService.downloadRecents(for: userId) { // Downloads recents in background
            case .success(let dataArray):
                if savedRecents.users != dataArray {
                    cacheManager.addTo(cacheManager.recentUsers, key: "users", value: RecentUsersHolder(dataArray))
                    await MainActor.run(body: {
                        withAnimation {
                            recentsArray = dataArray
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
            switch await dataService.downloadRecents(for: userId) {
            case .success(let dataArray):
                cacheManager.addTo(cacheManager.recentUsers, key: "users", value: RecentUsersHolder(dataArray))
                await MainActor.run {
                    withAnimation {
                        isLoading = false
                        recentsArray = dataArray
                        showRecents = true
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    isLoading = false
                }
                showAlert(title: "Error while fetching recents", message: error.localizedDescription)
            }
        }
    }
    
    /// Adds user to recent list
    func addToRecents(_ user: UserModel) {
        if !recentsArray.contains(user) {
            if recentsArray.count >= Limits.usersInRecentsLimit {
                recentsArray.removeLast(recentsArray.count - Limits.usersInRecentsLimit + 1)
            }
            recentsArray.insert(user, at: 0)
        } else {
            if let index = recentsArray.firstIndex(of: user) {
                recentsArray.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
            }
        }
        cacheManager.addTo(cacheManager.recentUsers, key: "users", value: RecentUsersHolder(recentsArray))
        Task {
            await dataService.saveRecents(recentsArray, id: userId)
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
