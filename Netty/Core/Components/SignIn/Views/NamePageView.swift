//
//  NamePageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct NamePageView: View {
    
    enum FocusedValue {
        case name, lastName
    }
    
    @ObservedObject private var vm: SignUpViewModel
    
    @FocusState private var activeField: FocusedValue?
    
    init(vm: SignUpViewModel) {
        self.vm = vm
    }

    
    var body: some View {
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
                    TextField("First name", text: $vm.firstNameTextField) { activeField = .lastName }
                        .textContentType(.givenName)
                        .autocorrectionDisabled(true)
                        .focused($activeField, equals: .name)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .name
                        })
                        
                    
                    TextField("Last name", text: $vm.lastNameTextField) { UIApplication.shared.endEditing() }
                        .textContentType(.familyName)
                        .autocorrectionDisabled(true)
                        .focused($activeField, equals: .lastName)
                        .padding()
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            activeField = .lastName
                        })
                
                    DatePicker("Birthday", selection: $vm.birthDate, in: vm.dateRangeFor18yearsOld, displayedComponents: .date)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 55)
                        .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                            UIApplication.shared.endEditing()
                        })
                }
                .padding()
                
                Spacer()
                
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
            .background(Color.theme.background.ignoresSafeArea().onTapGesture {
                UIApplication.shared.endEditing()
            })
        }
    }
}
