//
//  ForgotPasswordCreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 9/13/22.
//

import SwiftUI

struct ForgotPasswordCreatePasswordPageView: View {
    
    @ObservedObject private var vm: ForgotPasswordViewModel
    
    init(vm: ForgotPasswordViewModel) {
        self.vm = vm
    }
    
    private let text = "Passwords do not match"
    
    enum FocusedValue {
        case pass, confPass
    }
    
    @FocusState private var activeField: FocusedValue?
    
    
    var body: some View {
        ZStack {
            VStack() {
                
                Spacer(minLength: 0)
                
                // Fields
                VStack(spacing: 10) {
                    
                    SecureInputView("New password", text: $vm.passwordField) { activeField = .confPass }
                        .focused($activeField, equals: .pass)
                    
                    PasswordStrongnessView(message: $vm.passwordMessage)
                    
                    SecureInputView("Confirm new password", text: $vm.passwordConfirmField) { UIApplication.shared.endEditing() }
                        .focused($activeField, equals: .confPass)
                }
                .padding(.horizontal)
                
                if vm.showDontMatchError {
                    HStack {
                        
                        Spacer(minLength: 0)
                        
                        Text(text)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                        
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 0)
                
                Spacer(minLength: 0)
                
                // Buttons
                HStack {
                    
                    Spacer(minLength: 0)
                    
                    // Next button
                    Button(action: {
                        Task {
                            await vm.changePassword()
                        }
                    }, label: {
                        Text("Change password")
                            .font(.title3)
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.passwordNextButtonDisabled)
                    .padding()
                }
            }
            
            if vm.changingPasswordIsLoading {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(vm.changingPasswordIsLoading)
        .disabled(vm.changingPasswordIsLoading)
        .alert(vm.alertTitle, isPresented: $vm.showAlert, actions: {}, message: {
            Text(vm.alertMessage)
        })
        .navigationTitle("Create new Password")
        .background(Color(uiColor: .systemBackground).onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}






struct ForgotPasswordCreatePasswordPageView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordCreatePasswordPageView(vm: ForgotPasswordViewModel(path: .constant(NavigationPath()), showAlertOnLogInScreen: lol))
    }
    
    static func lol(_ dawda: String, _ dawd: String) {
        
    }
}
