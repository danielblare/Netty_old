//
//  ForgotPasswordEmailPageView.swift
//  Netty
//
//  Created by Danny on 9/13/22.
//

import SwiftUI
import CloudKit
import Combine

struct ForgotPasswordEmailPageView: View {
    
    // View Model
    @StateObject private var vm: ForgotPasswordViewModel
    
    // Focused field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case email, code
    }
    
    init(path: Binding<NavigationPath>, showAlertOnLogInScreen: @escaping (_ title: String, _ message: String) -> ()) {
        _vm = .init(wrappedValue: ForgotPasswordViewModel(path: path, showAlertOnLogInScreen: showAlertOnLogInScreen))
    }
    
    var body: some View {
        VStack {
            
            Spacer(minLength: 0)

            // Title
            Text("Enter e-mail that is connected to your account:")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            
            VStack(spacing: 30) {
                
                // Email text field
                VStack(spacing: 0) {
                    TextField("E-mail", text: $vm.emailTextField) { vm.showCodeTextField ? activeField = .code : UIApplication.shared.endEditing() }
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .disabled(vm.emailTextFieldIsDisabled)
                        .autocorrectionDisabled(true)
                        .focused($activeField, equals: .email)
                        .overlay(alignment: .trailing) {
                            if vm.showSucceedStatusIcon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                        }
                        .padding()
                        .onReceive(Just(vm.emailTextField)) { _ in
                            if vm.emailTextField.count > Limits.emailSymbolsLimit {
                                vm.emailTextField = String(vm.emailTextField.prefix(Limits.emailSymbolsLimit))
                            }
                        }

                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .email
                        })
                        .padding(.horizontal)
                    
                    // Timer and send email button
                    HStack() {
                        if vm.showTimer {
                            Text(vm.timeRemaining)
                                .padding(.horizontal, 30)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        Spacer(minLength: 0)
                        
                        Button(vm.emailButtonText.rawValue) {
                            Task {
                                await vm.emailButtonPressed()
                            }
                        }
                        .disabled(vm.emailButtonDisabled)
                        .padding(.horizontal, 25)
                        .font(.subheadline)
                        .buttonStyle(.borderless)
                        .accentColor(.blue)
                    }
                    .padding(.vertical, 10)
                }
                
                // Code text field
                if vm.showCodeTextField {
                    TextField("Confirmation code", text: $vm.codeTextField) { !vm.confirmButtonDisabled ? vm.confirmButtonPressed() : UIApplication.shared.endEditing() }
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($activeField, equals: .code)
                        .overlay(alignment: .trailing) {
                            if vm.showFailStatusIcon {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            
                        }
                        .onReceive(Just(vm.codeTextField)) { _ in
                            if vm.codeTextField.count > Limits.oneTimePasscode {
                                vm.codeTextField = String(vm.codeTextField.prefix(Limits.oneTimePasscode))
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .code
                        })
                        .padding(.horizontal)
                        .onAppear { activeField = .code }
                }
            }
            
            Spacer(minLength: 0)
            
            Spacer(minLength: 0)
            
            // Buttons
            HStack {
                
                Spacer(minLength: 0)
                
                if vm.codeCheckPassed {
                    NavigationLink {
                        ForgotPasswordCreatePasswordPageView(vm: vm)
                    } label: {
                        HStack {
                            Text("Next")
                                .font(.title3)
                            
                            Image(systemName: "arrow.forward")
                        }
                    }
                    .disabled(vm.emailNextButtonDisabled)
                    .padding()
                    
                } else {
                    Button {
                        vm.confirmButtonPressed()
                    } label: {
                        Text("Confirm")
                            .padding(.horizontal, 5)
                            .font(.title3)
                    }
                    .disabled(vm.confirmButtonDisabled)
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            
        }
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}, message: {
            Text(vm.alertMessage)
        })
        .navigationTitle("E-mail verification")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct ForgotPasswordEmailPageView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordEmailPageView(path: .constant(.init()), showAlertOnLogInScreen: lol)
        ForgotPasswordEmailPageView(path: .constant(.init()), showAlertOnLogInScreen: lol)
    }
    
    static func lol(_ dawda: String, _ dawd: String) {
        
    }
}

