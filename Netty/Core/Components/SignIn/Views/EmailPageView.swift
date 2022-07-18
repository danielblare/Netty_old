//
//  EmailPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI
import Combine

struct EmailPageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    
    enum FocusedValue {
        case email, code
    }
    
    @FocusState private var activeField: FocusedValue?

    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("Enter your e-mail")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
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
                                if vm.showSuccedStatusIcon {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .onAppear {
                                            HapticManager.instance.notification(of: .success)
                                        }
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
                            
                            Spacer()
                            
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
                        TextField("Confirmation code", text: $vm.codeTextField) { !vm.confirmButtonDisabeld ? vm.confirmButtonPressed() : UIApplication.shared.endEditing() }
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
                
                Spacer()
                
                Spacer()
                
                // Buttons
                HStack {
                    Button {
                        vm.moveToThePreviousRegistrationLevel()
                    } label: {
                        Text("Back")
                            .padding(.horizontal, 5)
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .padding()
                    
                    
                    Spacer()
                    
                    if vm.codeCheckPassed {
                        Button {
                            vm.moveToTheNextRegistrationLevel()
                        } label: {
                            Text("Next")
                                .padding(.horizontal, 5)
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                    } else {
                        Button {
                            vm.confirmButtonPressed()
                        } label: {
                            Text("Confirm")
                                .padding(.horizontal, 5)
                                .font(.title3)
                        }
                        .disabled(vm.confirmButtonDisabeld)
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                
            }
            .alert(isPresented: $vm.showAlert, content: {
                vm.getAlert()
            })
            .navigationTitle("Create account")
            .background(Color.theme.background.ignoresSafeArea().onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}


struct Previews_EmailPageView_Previews: PreviewProvider {
    static var previews: some View {
        EmailPageView(vm: SignUpViewModel())
    }
}
