//
//  LogInView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI
import CloudKit

class LogInViewModel: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
}

struct LogInView: View {
    
    @StateObject private var vm = LogInViewModel()

    @EnvironmentObject private var logInAndOutVm: LogInAndOutViewModel
    
    // Username and password text fields
    @State private var username: String = ""
    @State private var password: String = ""
        
    // Focused Field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case username, password
    }
    
    var body: some View {
        NavigationStack(path: $vm.path) {
            VStack {
                
                // Logo
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
                
                // Username textField
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
                
                // Password textField
                SecureInputView("Password", text: $password) { /* next */ }
                    .focused($activeField, equals: .password)
                    .padding(.horizontal)
                
                // Error message and forgot password
                HStack {
                    Text(logInAndOutVm.warningMessage.rawValue)
                        .font(.footnote)
                        .foregroundColor(.red)
                    
                    Spacer(minLength: 0)
                    
                    NavigationLink {
                        ForgotPasswordEmailPageView()
                    } label: {
                        Text("Forgot password?")
                            .font(.footnote)
                    }
                    
                }
                .padding(.horizontal)
                
                // Log in button
                Button {
                    Task {
                        await logInAndOutVm.logIn(username: username, password: password)
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
                
                // Sign up button
                HStack(spacing: 5) {
                    Text("Don't have an account?")
                        .font(.footnote)
                    
                    NavigationLink {
                        NamePageView()
                    } label: {
                        Text("Sign Up")
                            .font(.footnote)
                    }
                }
                .padding(.bottom)
                .padding(.top, 2)
                
            }
            .toolbar(.hidden)
            .background(Color(uiColor: .systemBackground).onTapGesture {
                UIApplication.shared.endEditing()
            })
            .disabled(logInAndOutVm.isLoading)
            .overlay {
                if logInAndOutVm.isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                username = ""
                password = ""
            }
        }
        .environmentObject(vm)
    }
}

struct LogInView_Previews: PreviewProvider {
    
    static var previews: some View {
        LogInView()
            .environmentObject(LogInAndOutViewModel())
        LogInView()
            .environmentObject(LogInAndOutViewModel())
    }
}
