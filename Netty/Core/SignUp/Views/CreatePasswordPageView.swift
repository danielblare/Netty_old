//
//  CreatePasswordPageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct CreatePasswordPageView: View {
    
    @ObservedObject private var vm: SignUpViewModel
    
    enum FocusedValue {
        case pass, confPass
    }
    
    @FocusState private var activeField: FocusedValue?
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }
    
    
    var body: some View {
        VStack() {

            Spacer(minLength: 0)
            
            // Fields
            VStack(spacing: 10) {
                
                SecureInputView("Password", text: $vm.passwordField) { activeField = .confPass }
                    .focused($activeField, equals: .pass)
                
                PasswordStrongLevelView(message: $vm.passwordMessage)
                
                SecureInputView("Confirm password", text: $vm.passwordConfirmField) { UIApplication.shared.endEditing() }
                    .focused($activeField, equals: .confPass)
            }
            .padding()
            
            Spacer(minLength: 0)
            
            Spacer(minLength: 0)
            
            // Buttons
            HStack {
                
                Spacer(minLength: 0)
                
                // Next button
                Button(action: {
                    vm.createAccount()
                }, label: {
                    Text("Create account")
                        .font(.title3)
                })
                .buttonStyle(.borderedProminent)
                .disabled(vm.passwordNextButtonDisabled)
                .padding()
            }
        }
        .navigationTitle("Create a Password")
        .background(Color.theme.background.onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}

struct Previews_CreatePasswordPageView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordPageView(vm: SignUpViewModel())
    }
}
