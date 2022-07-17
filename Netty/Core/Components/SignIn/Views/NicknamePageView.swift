//
//  NicknamePageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct NicknamePageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    
    enum FocusedValue {
        case nick
    }
    
    @FocusState private var activeField: FocusedValue?
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    
    var body: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("It's time to create a nickname")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Field
                VStack(spacing: 15) {
                    ZStack {
                        
                        // Progress view
                        if vm.nicknameIsChecking {
                            HStack {
                                Spacer()
                                
                                ProgressView().padding()
                            }
                        }
                        
                        // Checkmark if availability test was succeed
                        if vm.availabilityIsPassed {
                            HStack {
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .padding()
                            }
                        } else if vm.nicknameError == .nameIsUsed { // Xmark if name is already used
                            HStack {
                                Spacer()
                                
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                        
                        // TextField
                        TextField("Nickname", text: $vm.nicknameTextField) { !vm.nextButtonIsDisabled ? vm.moveToTheNextRegistrationLevel() : UIApplication.shared.endEditing() }
                            .autocorrectionDisabled(true)
                            .textContentType(.nickname)
                            .focused($activeField, equals: .nick)
                            .padding()
                            .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                                activeField = .nick
                            })
                    }
                    
                    // Error description
                    HStack {
                        Text(vm.nicknameError.rawValue)
                            .padding(.horizontal, 5)
                            .font(.footnote)
                            .foregroundColor(.red)
                            
                        
                        Spacer()
                    }
                    
                }
                .padding()
                
                Spacer()
                
                // Buttons
                HStack {
                    
                    // Back button
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

                    Button {
                        vm.moveToTheNextRegistrationLevel()
                    } label: {
                        Text("Next")
                            .padding(.horizontal, 5)
                            .font(.title3)
                    }
                    .disabled(vm.nextButtonIsDisabled)
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Create Nickname")
            .background(Color.theme.background.ignoresSafeArea().onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}
