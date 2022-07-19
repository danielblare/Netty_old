//
//  LogInView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI

struct LogInView: View {
    
    @StateObject private var vm = LogInViewModel()
    
    enum FocusedValue {
        case username, password
    }
        
    @FocusState private var activeField: FocusedValue?
        
    var body: some View {
        NavigationView {
            VStack {
                                    
                Image("logo_full")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.vertical, 70)
                
                TextField("Username or e-mail", text: $vm.usernameTextField) { activeField = .password }
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
                
                SecureInputView("Password", text: $vm.passwordTextField) { /* next */ }
                    .focused($activeField, equals: .password)
                    .padding(.horizontal)
                
                Button {
                    
                } label: {
                    Text("Log In")
                        .foregroundColor(.theme.textOnAccentColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            Rectangle()
                                .foregroundColor(.accentColor)
                                .cornerRadius(15)
                        )
                        .padding()
                }

               
                
                Spacer()
                
                Divider()
                
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
            .navigationBarHidden(true)
            .background(Color.theme.background.onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
            .preferredColorScheme(.light)
        LogInView()
            .preferredColorScheme(.dark)
    }
}
