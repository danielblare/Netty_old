//
//  PublicProfileViewModel.swift
//  Netty
//
//  Created by Danny on 11/8/22.
//

import SwiftUI
import CloudKit

class PublicProfileViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""

    let user: UserModel
    
    @Published var userInfoIsLoading: Bool = true
    @Published var postsAreLoading: Bool = true
    
    // Posts array
    @Published var posts: [PostModel] = []
    
    // User's first name
    @Published var firstName: String = ""
    
    // User's last name
    @Published var lastName: String = ""
    
    // User's nickname
    @Published var nickname: String = ""
    
    init(_ userModel: UserModel) {
        user = userModel
        getData()
    }
    
    /// Gets all user's data
    func getData() {
        
    }
    
    /// Deletes user's data from cache and downloads new fresh data from database
    func sync() async {

    }
    
    /// Shows alert on the screen
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }

}
