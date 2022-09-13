//
//  LogInView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI
import CloudKit

struct DataObject: Identifiable, Hashable {
    let id = UUID()
}


struct LogInView: View {
    
    @EnvironmentObject private var vm: LogInAndOutViewModel
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var path = NavigationPath()
        
    enum FocusedValue {
        case username, password
    }
    
    @FocusState private var activeField: FocusedValue?
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        Image("logo_full")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .padding(.vertical)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: 250)
                    
                    TextField("Username or e-mail", text: $username) { activeField = .password }
                        .textContentType(.username)
                        .textContentType(.emailAddress)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled(true)
                        .focused($activeField, equals: .username)
                        .padding()
                        .padding(.vertical, 0.5)
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .username
                        })
                        .padding(.horizontal)
                    
                    SecureInputView("Password", text: $password) { /* next */ }
                        .focused($activeField, equals: .password)
                        .padding(.horizontal)
                    
                    HStack {
                        Text(vm.warningMessage.rawValue)
                            .font(.footnote)
                            .foregroundColor(.red)
                        
                        Spacer(minLength: 0)
                        
                        NavigationLink(value: DataObject.init()) {
                            Text("Forgot password?")
                                .font(.footnote)
                        }
                        
                    }
                    .navigationDestination(for: DataObject.self) { _ in
                        ForgotPasswordEmailPageView(path: $path, showAlertOnLogInScreen: vm.showAlert)
                    }
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await vm.logIn(username: username, password: password)
                        }
                    } label: {
                        Text("Log In")
                            .font(.title3)
                            .padding(5)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .buttonStyle(.borderedProminent)
                    
                    
                    
                    Spacer(minLength: 0)
                    
                    Divider()
                    
                    HStack(spacing: 5) {
                        Text("Don't have an account?")
                            .font(.footnote)
                        
                        NavigationLink {
                            NamePageView(userRecordId: $vm.userRecordId, path: $path)
                        } label: {
                            Text("Sign Up")
                                .font(.footnote)
                        }
                    }
                    .padding(.bottom)
                    .padding(.top, 2)
                    
                }
                .navigationBarHidden(true)
                .background(Color.theme.background.onTapGesture {
                    UIApplication.shared.endEditing()
            })
                .disabled(vm.isLoading)
                
                
                if vm.isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                username = ""
                password = "" 
            }
        }
    }
}

struct LogInView_Previews: PreviewProvider {
    @StateObject static var vm = LogInAndOutViewModel()
    
    static var previews: some View {
        LogInView()
            .environmentObject(LogInAndOutViewModel())
        LogInView()
            .environmentObject(LogInAndOutViewModel())
    }
}
