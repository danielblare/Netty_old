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
                    TextField("Nickname", text: $vm.nicknameTextField) { UIApplication.shared.endEditing() }
                        .autocorrectionDisabled(true)
                        .textContentType(.nickname)
                        .keyboardType(.asciiCapable)
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
            
            Spacer()
            
            // Buttons
            HStack {
                
                Spacer()
                
                NavigationLink {
                    CreatePasswordPageView(vm: vm)
                } label: {
                    HStack {
                        Text("Next")
                            .font(.title3)
                        
                        Image(systemName: "arrow.forward")
                    }
                }
                .disabled(vm.nicknameNextButtonDisabled)
                .padding()
            }
        }
        .navigationTitle("Create Nickname")
        .background(Color.theme.background.onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
    
}
