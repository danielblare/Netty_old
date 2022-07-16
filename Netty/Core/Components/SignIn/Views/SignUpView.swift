//
//  SignUpView.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI

struct SignUpView: View {
    
    @EnvironmentObject private var vm: SignUpViewModel
    @FocusState private var isFirstNameActive: Bool
    @FocusState private var isLastNameActive: Bool
    @FocusState private var isEmailActive: Bool
    @FocusState private var isNicknameActive: Bool

    init() {
        print("View INIT")
    }
    
    var body: some View {
        switch vm.registrationLevel {
        case .name:
            namePage
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case .email:
            emailPage
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }
}


extension SignUpView {
    private var namePage: some View {
        NavigationView {
            VStack() {
                Text("Let's add your personal data")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(spacing: 15) {
                    TextField("First name", text: $vm.firstNameTextField)
                        .autocorrectionDisabled(true)
                        .focused($isFirstNameActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isFirstNameActive = true
                        })
                        
                    
                    TextField("Last name", text: $vm.lastNameTextField)
                        .autocorrectionDisabled(true)
                        .focused($isLastNameActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isLastNameActive = true
                        })
                    
                    DatePicker("Birthday", selection: $vm.birthDate, in: vm.dateRangeFor18yearsOld, displayedComponents: .date)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15))
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            vm.moveToTheNextRegistrationLevel()
                        }
                    } label: {
                        Text("Next")
                            .padding(.horizontal, 5)
                    }
                    .disabled(!vm.showNextButton)
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .accentColor(.theme.accent)
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
                Text("Now type your e-mail and nickname")
                    .padding()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(spacing: 15) {
                    TextField("E-mail", text: $vm.emailTextField)
                        .autocorrectionDisabled(true)
                        .focused($isEmailActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isEmailActive = true
                        })
                        
                    
                    TextField("Nickname", text: $vm.nicknameTextField)
                        .autocorrectionDisabled(true)
                        .focused($isNicknameActive)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            isNicknameActive = true
                        })
                    
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            vm.moveToTheNextRegistrationLevel()
                        }
                    } label: {
                        Text("Next")
                            .padding(.horizontal, 5)
                    }
                    .disabled(!vm.showNextButton)
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .accentColor(.theme.accent)
                }
                
            }
            .navigationTitle("Create account")
            .background(Color.theme.background.onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}






struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(SignUpViewModel())
        SignUpView()
            .preferredColorScheme(.dark)
            .environmentObject(SignUpViewModel())
    }
}
