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
    
    @Published var recentsArray: [FindUserModel] = []
    @Published var findedArray: [FindUserModel] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var showRecents: Bool = false
    @Published var showFinded: Bool = false
    private let id: CKRecord.ID?
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    private let dataService = FindUserModelService.instance
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID?) {
        self.id = id
        Task {
            await getResents()
        }
    }
    
    private var searchTask: Task<(), Never>?
    
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
        
        showFinded = false
    }
    
    func executeQuery() async {
        guard let id = id else { return }
        if !searchText.isEmpty {
            searchTask = Task {
                await MainActor.run(body: {
                    isLoading = true
                })
                switch await dataService.downloadSearching(searchText, id: id) {
                case .success(let resultArray):
                    if let task = searchTask, !task.isCancelled {
                        await MainActor.run(body: {
                            isLoading = false
                            findedArray = resultArray
                            showFinded = true
                        })
                    }
                case .failure(let error):
                    showAlert(title: "Error while searching", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func getResents() async {
        print("getting recents")
        guard let id = id else { return }
        if let savedRecents = cacheManager.getFrom(cacheManager.recentUsers, key: "users") {
            await MainActor.run {
                withAnimation {
                    recentsArray = savedRecents.users
                    showRecents = true
                }
            }
            switch await dataService.downloadRecents(for: id) {
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
            await MainActor.run(body: {
                isLoading = true
            })
            switch await dataService.downloadRecents(for: id) {
            case .success(let dataArray):
                cacheManager.addTo(cacheManager.recentUsers, key: "users", value: RecentUsersHolder(dataArray))
                await MainActor.run(body: {
                    withAnimation {
                        isLoading = false
                        recentsArray = dataArray
                        showRecents = true
                    }
                })
            case .failure(let error):
                showAlert(title: "Error while fetching recents", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        isLoading = false
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
}
