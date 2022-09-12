//
//  LogInView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI

struct LogInView: View {
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
    
    @State private var username: String = ""
    @State private var password: String = ""
        
    enum FocusedValue {
        case username, password
    }
    
    @FocusState private var activeField: FocusedValue?
    
    var body: some View {
        NavigationView {
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
                        Text(logInAndOutViewModel.warningMessage.rawValue)
                            .font(.footnote)
                            .foregroundColor(.red)
                        
                        Spacer(minLength: 0)
                        
                        NavigationLink {
                            
                        } label: {
                            Text("Forgot password?")
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await logInAndOutViewModel.logIn(username: username, password: password)
                            username = ""
                            password = ""
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
                            NamePageView(userRecordId: $logInAndOutViewModel.userRecordId)
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
                .disabled(logInAndOutViewModel.isLoading)
                
                
                if logInAndOutViewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}
