//
//  CreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct CreatePasswordPageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    private let text = "Passwords do not match"
    
    enum FocusedValue {
        case pass, confPass
    }
    
    @FocusState private var activeField: FocusedValue?
    
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
                    
                    PasswordStrongnessView(message: $vm.passwordMessage)
                    
                    SecureInputView("Confirm password", text: $vm.passwordConfirmField) { UIApplication.shared.endEditing() }
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
                            await vm.createAccount()
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

