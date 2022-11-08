//
//  ForgotPasswordCreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 9/13/22.
//

import SwiftUI
import Combine

struct ForgotPasswordCreatePasswordPageView: View {
        
    // View Model
    @ObservedObject private var vm: ForgotPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(vm: ForgotPasswordViewModel) {
        self.vm = vm
    }
        
    // Focused field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case pass, confPass
    }
    
    var body: some View {
        VStack() {
            
            Spacer(minLength: 0)
            
            // Fields
            VStack(spacing: 10) {
                
                SecureInputView("New password", text: $vm.passwordField) { activeField = .confPass }
                    .focused($activeField, equals: .pass)
                    .onReceive(Just(vm.passwordField)) { _ in
                        if vm.passwordField.count > Limits.passwordSymbolsLimit {
                            vm.passwordField = String(vm.passwordField.prefix(Limits.passwordSymbolsLimit))
                        }
                    }
                
                PasswordStrengthView(message: $vm.passwordMessage)
                
                SecureInputView("Confirm new password", text: $vm.passwordConfirmField) { UIApplication.shared.endEditing() }
                    .focused($activeField, equals: .confPass)
                    .onReceive(Just(vm.passwordConfirmField)) { _ in
                        if vm.passwordConfirmField.count > Limits.passwordSymbolsLimit {
                            vm.passwordConfirmField = String(vm.passwordConfirmField.prefix(Limits.passwordSymbolsLimit))
                        }
                    }
            }
            .padding(.horizontal)
            
            // Password error
            if vm.showMatchingError {
                HStack {
                    
                    Spacer(minLength: 0)
                    
                    Text("Passwords do not match")
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
                        await vm.changePassword(prMode: presentationMode)
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
        .navigationBarBackButtonHidden(vm.changingPasswordIsLoading)
        .disabled(vm.changingPasswordIsLoading)
        .overlay {
            if vm.changingPasswordIsLoading {
                ProgressView()
            }
        }
        .navigationTitle("Create new Password")
        .background(Color(uiColor: .systemBackground).onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}






struct ForgotPasswordCreatePasswordPageView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordCreatePasswordPageView(vm: ForgotPasswordViewModel())
    }
}
