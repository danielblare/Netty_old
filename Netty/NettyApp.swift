//
//  NettyApp.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI
import Combine

class LogInAndOutViewModel: ObservableObject {
    @Published var userSignedIn: Bool // Is signed in logica
    private let manager = LogInAndOutManager.instance
    
    @Published var showAlert: Bool = false
    var error: Error? = nil
    var alertText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    init() {
        userSignedIn = true
    }
    
    func logIn(username: String, password: String) async {
        let result = await manager.logIn(username: username, password: password)
        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    self.error = error
                    self.alertText = "Error while logging in"
                    self.showAlert = true
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
    
    func logOut() async {
        let result = await manager.logOut()
        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    self.error = error
                    self.alertText = "Error while logging out"
                    self.showAlert = true
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
            .alert(isPresented: $logInAndOutViewModel.showAlert) {
                Alert(
                    title: Text(logInAndOutViewModel.alertText),
                    message: Text(logInAndOutViewModel.error?.localizedDescription ?? ""),
                    dismissButton: .cancel()
                )
            }
        }
    }
}
