//
//  NettyApp.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI
import Combine
import CloudKit

enum WarningMessage: String {
    case usernameIsShort = "Username less than 3 symbols"
    case passwordIsShort = "Password less than 8 symbols"
    case none = ""
}

class LogInAndOutViewModel: ObservableObject {
    
    @Published var userRecordId: CKRecord.ID? = nil
    
    private let manager = LogInAndOutManager.instance
    
    @Published var warningMessage: WarningMessage = .none
    
    @Published var isLoading: Bool = false
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
        
    init() {
        Task {
            let result = await manager.checkLoggedInDevise()
            await MainActor.run(body: {
                switch result {
                case .success(let id):
                    userRecordId = id
                case .failure(_):
                    userRecordId = nil
                }
            })
        }
        getiCloudStatus()
    }
    
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
            await MainActor.run(body: {
                warningMessage = .none
                isLoading = true
            })
            let result = await manager.logIn(username: username, password: password)
            switch result {
            case .success(let id):
                if let id = id {
                    await MainActor.run(body: {
                        withAnimation {
                            userRecordId = id
                        }
                    })
                    await manager.addLoggedInDevice(for: id)
                } else {
                    showAlert(title: "Error while logging in", message: "Password is incorrect")
                }
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
            await MainActor.run(body: {
                isLoading = false
            })
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    func logOut() async {
        let result = await manager.logOut()
        switch result {
        case .success(_):
            if let id = userRecordId {
                await manager.removeLoggedInDevice(for: id)
            }
            await MainActor.run(body: {
                withAnimation {
                    userRecordId = nil
                }
            })
        case .failure(let error):
            showAlert(title: "Error while logging out", message: error.localizedDescription)
        }
    }
    
    private func getiCloudStatus() {
        CKContainer.default().accountStatus {  returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    print("Could not determine")
                case .available:
                    print("iCloud is available")
                case .restricted:
                    print("iCloud is restricted")
                case .noAccount:
                    print("No account")
                case .temporarilyUnavailable:
                    print("Temporariry unavailable")
                @unknown default:
                    print("iCloud default")
                }
            }
        }
    }
}

@main
struct NettyApp: App {
    
    /*
    fetch logged in device when LogInAndOutViewModel is initializing
     make password encrypted
     */
    @StateObject private var logInAndOutViewModel = LogInAndOutViewModel()
    @State private var showLaunchView: Bool = true
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor(.theme.accent)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor(.theme.accent)]
        UITableView.appearance().backgroundColor = UIColor.clear
        UINavigationBar.appearance().backgroundColor = UIColor(.theme.background)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if logInAndOutViewModel.userRecordId != nil {
                    MainScreenView()
                        .transition(.opacity)
                } else {
                    LogInView()
                        .transition(.opacity)
                }
                    
                
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                    }
                }
                .zIndex(2.0)
            }
            .environmentObject(logInAndOutViewModel)
            .persistentSystemOverlays(.hidden)
            .alert(Text(logInAndOutViewModel.alertTitle), isPresented: $logInAndOutViewModel.showAlert, actions: {}, message: {
                Text(logInAndOutViewModel.alertMessage)
            })
        }
    }
}
