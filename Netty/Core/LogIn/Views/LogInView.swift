//
//  LogInView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI
import CloudKit

struct LogInView: View {
    
    let warningMessage: String
    let logInFunc: (String, String) async -> ()
    let isLoading: Bool
    @Binding var userRecordId: CKRecord.ID?

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
                        Text(warningMessage)
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
                            await logInFunc(username, password)
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
                            NamePageView(userRecordId: $userRecordId)
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
                .disabled(isLoading)
                
                
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct LogInView_Previews: PreviewProvider {
    @StateObject static var vm = LogInAndOutViewModel()
    
    static var previews: some View {
        LogInView(warningMessage: vm.warningMessage.rawValue, logInFunc: vm.logIn, isLoading: vm.isLoading, userRecordId: $vm.userRecordId)
    }
}
