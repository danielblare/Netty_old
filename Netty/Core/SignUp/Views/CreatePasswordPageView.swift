//
//  CreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI
import Combine

struct CreatePasswordPageView: View {
    
    @EnvironmentObject private var logInAndOutVm: LogInAndOutViewModel
    @EnvironmentObject private var logInVm: LogInViewModel
    
    // View Model
    @ObservedObject private var vm: SignUpViewModel
    
    // Focused field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case pass, confPass
    }
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        ZStack {
            VStack() {
                
                Spacer(minLength: 0)
                
                // Fields
                VStack(spacing: 10) {
                    
                    SecureInputView("Password", text: $vm.passwordField) { activeField = .confPass }
                        .focused($activeField, equals: .pass)
                        .onReceive(Just(vm.passwordField)) { _ in
                            if vm.passwordField.count > Limits.passwordSymbolsLimit {
                                vm.passwordField = String(vm.passwordField.prefix(Limits.passwordSymbolsLimit))
                            }
                        }
                    
                    PasswordStrengthView(message: $vm.passwordMessage)
                    
                    SecureInputView("Confirm password", text: $vm.passwordConfirmField) { UIApplication.shared.endEditing() }
                        .focused($activeField, equals: .confPass)
                        .onReceive(Just(vm.passwordConfirmField)) { _ in
                            if vm.passwordConfirmField.count > Limits.passwordSymbolsLimit {
                                vm.passwordConfirmField = String(vm.passwordConfirmField.prefix(Limits.passwordSymbolsLimit))
                            }
                        }
                }
                .padding(.horizontal)
                
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
                            await vm.createAccount(userId: $logInAndOutVm.userId, path: $logInVm.path)
                        }
                    }, label: {
                        Text("Create account")
                            .font(.title3)
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.passwordNextButtonDisabled)
                    .padding()
                }
            }
            
            if vm.creatingAccountIsLoading {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(vm.creatingAccountIsLoading)
        .disabled(vm.creatingAccountIsLoading)
        .alert(vm.alertTitle, isPresented: $vm.showAlert, actions: {}, message: {
            Text(vm.alertMessage)
        })
        .navigationTitle("Create a Password")
        .background(Color(uiColor: .systemBackground).onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
    
}

