//
//  FollowersPageViewModel.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI
import CloudKit


final class FollowersPageViewModel: ObservableObject {
    
    @Published var followers: [UserModel]? = nil
    
    @Published var isLoading: Bool = false
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""

    let ownId: CKRecord.ID
    
    init(refs: [CKRecord.Reference], ownId: CKRecord.ID) {
        self.ownId = ownId
        Task {
            await MainActor.run {
                isLoading = true
            }
            switch await UserInfoService.instance.fetchUserDataForUsers(with: refs.map({ $0.recordID })) {
            case .success(let userModels):
                if let userModels = userModels {
                    await MainActor.run {
                        followers = userModels
                        withAnimation {
                            isLoading = false
                        }
                    }
                } else {
                    showAlert(title: "Error while fetching followers", message: "Some data is broken")
                    await MainActor.run {
                        isLoading = false
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching followers", message: error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
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
