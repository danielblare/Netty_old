//
//  NettyApp.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI
import Combine
import CloudKit

class LogInAndOutViewModel: ObservableObject {
    
    // Current user's recordID
    @Published var userId: CKRecord.ID?
    
    // Log in and out manager
    private let manager = LogInAndOutManager.instance
    
    // Error message
    @Published var warningMessage: WarningMessage = .none
    
    // Shows loading view if true
    @Published var isLoading: Bool = false
    
    // Alert
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
        
    init(id: CKRecord.ID? = nil) {
        userId = id
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            let status = await getiCloudStatus()
            
            if status == .available {
                let result = await manager.checkLoggedInDevise()
                await MainActor.run {
                    switch result {
                    case .success(let id):
                        isLoading = false
                        withAnimation {
                            userId = id
                        }
                    case .failure(_):
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    /// Logs user in
    func logIn(username: String, password: String) async {
        if username.count < 3 {
            await MainActor.run(body: {
                warningMessage = .usernameIsShort
            })
        } else if password.count < 8 {
            await MainActor.run(body: {
                warningMessage = .passwordIsShort
            })
        } else {
            await MainActor.run {
                warningMessage = .none
                isLoading = true
            }
            switch await manager.logIn(username: username, password: password) {
            case .success(let id):
                if let id = id {
                    await MainActor.run {
                        isLoading = false
                        withAnimation {
                            userId = id
                        }
                    }
                    await manager.addLoggedInDevice(for: id)
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                    showAlert(title: "Error while logging in", message: "Password is incorrect")
                }
            case .failure(let error):
                await MainActor.run {
                    isLoading = false
                }
                showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    /// Shows alert
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    /// Logs user out
    func logOut() async {
        if let id = userId {
            switch await manager.logOut(for: id) {
            case .success(_):
                await MainActor.run(body: {
                    withAnimation {
                        userId = nil
                    }
                })
            case .failure(let error):
                showAlert(title: "Error while logging out", message: error.localizedDescription)
            }
        }
    }
    
    /// Gets user's iCloud status
    private func getiCloudStatus() async -> CKAccountStatus? {
        await withCheckedContinuation { cont in
            CKContainer.default().accountStatus { returnedStatus, returnedError in
                cont.resume(returning: returnedStatus)
            }
        }
    }
}


@main
struct NettyApp: App {
    
    @StateObject private var logInAndOutViewModel = LogInAndOutViewModel()
    @State private var showLaunchView: Bool = true
    
    init() {
//        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor(.theme.accent)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor(.theme.accent)]
//        UITableView.appearance().backgroundColor = UIColor.clear
//        UINavigationBar.appearance().backgroundColor = UIColor(.theme.background)
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.theme.accent)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if let id = logInAndOutViewModel.userId {
                    MainScreenView(userId: id)
                        .transition(.opacity)
                } else {
                    LogInView()
                       .transition(.opacity)
                }
                
                
                if showLaunchView {
                    LaunchView(showLaunchView: $showLaunchView)
                        .zIndex(2.0)
                }
            }
            .environmentObject(logInAndOutViewModel)
            .persistentSystemOverlays(.hidden)
            .alert(Text(logInAndOutViewModel.alertTitle), isPresented: $logInAndOutViewModel.showAlert, actions: {}, message: {
                Text(logInAndOutViewModel.alertMessage)
            })
        }
    }
}
