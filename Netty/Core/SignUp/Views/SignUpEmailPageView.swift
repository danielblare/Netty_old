//
//  SignUpEmailPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI
import Combine

struct SignUpEmailPageView: View {
    
    // View Model
    @ObservedObject private var vm: SignUpViewModel
    
    // Focused field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case email, code
    }
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        VStack {
            
            Spacer(minLength: 0)
            
            VStack(spacing: 30) {
                // TextField
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
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .email
                        })
                        .padding(.horizontal)
                    
                    
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
                        NicknamePageView(vm: vm)
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
        .navigationTitle("Enter your e-mail")
        .background(Color(uiColor: .systemBackground).onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}

