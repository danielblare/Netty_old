//
//  SignUpView.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI

struct SignUpView: View {
    
    @StateObject private var vm: SignUpViewModel = SignUpViewModel()

    @FocusState private var isFirstNameFieldActive: Bool
    @FocusState private var isLastNameFieldActive: Bool
    @FocusState private var isEmailFieldActive: Bool
    @FocusState private var isNicknameFieldActive: Bool

    var body: some View {
        switch vm.registrationLevel {
        case .name:
            namePage
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .email:
            emailPage
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .nickname:
            nicknamePage
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
    }
}

extension SignUpView {
    private var namePage: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("Let's add your personal data")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Fields
                VStack(spacing: 15) {
                    TextField("First name", text: $vm.firstNameTextField)
                        .autocorrectionDisabled(true)
                        .focused($isFirstNameFieldActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isFirstNameFieldActive = true
                        })
                        
                    
                    TextField("Last name", text: $vm.lastNameTextField)
                        .autocorrectionDisabled(true)
                        .focused($isLastNameFieldActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isLastNameFieldActive = true
                        })
                    
                    DatePicker("Birthday", selection: $vm.birthDate, in: vm.dateRangeFor18yearsOld, displayedComponents: .date)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15))
                }
                .padding()
                
                Spacer()
                
                // Buttons
                HStack {
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
            .navigationTitle("Welcome to Netty")
            .background(Color.theme.background.onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
    
    private var emailPage: some View {
        NavigationView {
            VStack() {
                
                // Subtitle
                Text("Enter your e-mail")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // TextField
                TextField("E-mail", text: $vm.emailTextField)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .focused($isEmailFieldActive)
                    .padding()
                    .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                        isEmailFieldActive = true
                    })
                    .padding()
                
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
            .navigationTitle("Create account")
            .background(Color.theme.background.onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
    
    private var nicknamePage: some View {
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
                        TextField("Nickname", text: $vm.nicknameTextField)
                            .disabled(vm.nicknameFieldIsDisabled)
                            .autocorrectionDisabled(true)
                            .focused($isNicknameFieldActive)
                            .padding()
                            .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                                isNicknameFieldActive = true
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
                    
                    // Check button if needed or next if availability test was passed
                    if !vm.availabilityIsPassed {
                        Button {
                            let nickname = vm.nicknameTextField
                            Task {
                                await vm.checkAvailability(of: nickname)
                            }
                        } label: {
                            Text("Check Availability")
                                .padding(.horizontal, 5)
                                .font(.title3)
                        }
                        .disabled(vm.checkButtonIsDisabled)
                        .buttonStyle(.borderedProminent)
                        .accentColor(.green)
                        .padding()
                    } else {
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
            }
            .navigationTitle("Create Nickname")
            .background(Color.theme.background.onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}


struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.light)
        SignUpView()
            .preferredColorScheme(.dark)
    }
}
