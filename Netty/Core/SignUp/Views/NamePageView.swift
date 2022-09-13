//
//  NamePageView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI
import CloudKit

struct NamePageView: View {
    
    enum FocusedValue {
        case name, lastName
    }
        
    @ObservedObject private var vm: SignUpViewModel
    
    init(userRecordId: Binding<CKRecord.ID?>, path: Binding<NavigationPath>) {
        self.vm = SignUpViewModel(userRecordId: userRecordId, path: path)
    }
    
    @FocusState private var activeField: FocusedValue?
    
    var body: some View {
        VStack {
            
            Spacer(minLength: 0)
            
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
            
            Spacer(minLength: 0)
            
            Spacer(minLength: 0)
            
            // Buttons
            HStack {
                Spacer(minLength: 0)
                
                NavigationLink {
                    SignUpEmailPageView(vm: vm)
                } label: {
                    HStack {
                        Text("Next")
                            .font(.title3)
                        
                        Image(systemName: "arrow.forward")
                    }
                }
                .disabled(vm.nameNextButtonDisabled)
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Welcome to Netty!")
        .background(Color.theme.background.onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}


