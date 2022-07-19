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
    
    @StateObject private var vm: SignUpViewModel = SignUpViewModel()
    
    @FocusState private var activeField: FocusedValue?
    
    var body: some View {
        VStack() {
            // Subtitle
            Text("Let's add some information about you")
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
                
                NavigationLink {
                    EmailPageView(vm: vm)
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
        .navigationTitle("Personal Data")
        .background(Color.theme.background.ignoresSafeArea().onTapGesture {
            UIApplication.shared.endEditing()
        })
    }
}



struct NamePageView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            NamePageView()
                .navigationTitle("Welcome to Netty!")
        }
    }
}
