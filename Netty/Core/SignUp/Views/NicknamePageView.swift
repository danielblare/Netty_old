//
//  NicknamePageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI
import Combine

struct NicknamePageView: View {
    
    // View Model
    @ObservedObject private var vm: SignUpViewModel
    
    // Focused field
    @FocusState private var activeField: FocusedValue?
    enum FocusedValue {
        case nick
    }
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    var body: some View {
        VStack() {

            Spacer(minLength: 0)
            
            // Field
            VStack(spacing: 15) {
                ZStack {
                    
                    // Progress view
                    if vm.nicknameIsChecking {
                        HStack {
                            Spacer(minLength: 0)
                            
                            ProgressView().padding()
                        }
                    }
                    
                    // Checkmark if availability test was succeed
                    if vm.availabilityIsPassed {
                        HStack {
                            Spacer(minLength: 0)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding()
                        }
                    } else if vm.nicknameError == .nameIsUsed { // Xmark if name is already used
                        HStack {
                            Spacer(minLength: 0)
                            
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
                        .onReceive(Just(vm.nicknameTextField)) { _ in
                            if vm.nicknameTextField.count > Limits.nicknameSymbolsLimit {
                                vm.nicknameTextField = String(vm.nicknameTextField.prefix(Limits.nicknameSymbolsLimit))
                            }
                        }
                }
                
                // Error description
                HStack {
                    Text(vm.nicknameError.rawValue)
                        .padding(.horizontal, 5)
                        .font(.footnote)
                        .foregroundColor(vm.nicknameError == .none ? .secondary : .red)
                    
                    
                    Spacer(minLength: 0)
                }
                
            }
            .padding()
            
            Spacer(minLength: 0)
            
            Spacer(minLength: 0)
            
            // Buttons
            HStack {
                
                Spacer(minLength: 0)
                
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
        .navigationTitle("Create a Nickname")
        .background(Color(uiColor: .systemBackground).onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}
