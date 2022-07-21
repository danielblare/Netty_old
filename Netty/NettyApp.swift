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
    @AppStorage("userSignedIn") var userSignedIn: Bool = false // Is signed in logic
    private let manager = LogInAndOutManager.instance
    
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        userSignedIn = false
    }
    
    func logIn(username: String, password: String) async {
        let result = await manager.logIn(username: username, password: password)
        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.showAlert(title: "Error while logging in", message: error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { _ in
                withAnimation {
                    self.userSignedIn = true
                }
            }
            .store(in: &cancellables)

    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    func logOut() async {
        let result = await manager.logOut()
        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.showAlert(title: "Error while logging out", message: error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { _ in
                withAnimation {
                    self.userSignedIn = false
                }
            }
            .store(in: &cancellables)

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
                if  logInAndOutViewModel.userSignedIn {
                    HomeView()
                        .environmentObject(logInAndOutViewModel)
                        .transition(.opacity)
                } else {
                    LogInView()
                        .environmentObject(logInAndOutViewModel)
                        .transition(.opacity)
                }
                
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                    }
                }
                .zIndex(2.0)
            }
            .alert(Text(logInAndOutViewModel.alertTitle), isPresented: $logInAndOutViewModel.showAlert, actions: {}, message: {
                Text(logInAndOutViewModel.alertMessage)
            })
        }
    }
}
