//
//  PersonalInfoPage.swift
//  Netty
//
//  Created by Danny on 10/4/22.
//
import SwiftUI
import CloudKit
import Combine

struct PersonalInfoPage: View {
    
    // Presentation mode to dismiss current page if error occurred
    @Environment(\.presentationMode) var presentationMode
    
    // View Model
    @StateObject private var vm: PersonalInfoViewModel
    
    // Confirmation dialog before saving changes
    @State private var confirmationDialogIsPresented: Bool = false
    
    init(id: CKRecord.ID) {
        _vm = .init(wrappedValue: PersonalInfoViewModel(id: id))
    }
    
    // Date range for date picker from 100 years ago to 18 years ago to prevent user choosing later date
    private var dateRange: ClosedRange<Date> {
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        return startingDate...endingDate
    }
    
    var body: some View {
        List {
            nicknamePart
            
            firstNamePart
            
            lastNamePart
            
            dateOfBirthPart
        }
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        }, message: {
            Text(vm.alertMessage)
        })
        .disabled(vm.isLoading)
        .navigationBarBackButtonHidden(vm.backButtonDisabled)
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { getToolbar() }
        .confirmationDialog("Are you sure you want to save changes?", isPresented: $confirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Save") {
                Task {
                    await vm.saveChanges()
                }
            }
        }
    }
    
    // Creates toolbar for navigationView
    @ToolbarContentBuilder private func getToolbar() -> some ToolbarContent {
        
        // Save changes button
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                confirmationDialogIsPresented = true
            }
            .disabled(vm.saveButtonDisabled)
        }
    }
    
    // Date of birth picker
    private var dateOfBirthPart: some View {
        DatePicker("Date of birth:", selection: $vm.dateOfBirthPicker, in: dateRange, displayedComponents: .date)
            .datePickerStyle(.compact)
            .foregroundColor(.secondary)
            .font(.callout)
            .padding(.vertical, 2)
    }
    
    // Nickname textField
    private var nicknamePart: some View {
        VStack(spacing: 0) {
            
            // Actual text field
            ZStack {
                
                // Text field title
                HStack {
                    Text("Nickname:")
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .font(.callout)
                    TextField("", text: $vm.nicknameTextField)
                        .autocorrectionDisabled(true)
                        .textContentType(.nickname)
                        .keyboardType(.asciiCapable)
                        .onReceive(Just(vm.nicknameTextField)) { _ in
                            if vm.nicknameTextField.count > Limits.nicknameSymbolsLimit {
                                vm.nicknameTextField = String(vm.nicknameTextField.prefix(Limits.nicknameSymbolsLimit))
                            }
                        }
                }
                
                // Loading view
                HStack {
                    Spacer(minLength: 0)
                    
                    if vm.nicknameIsChecking {
                        ProgressView()
                    }
                }
                
                // Status icon view
                HStack {
                    Spacer(minLength: 0)
                    
                    if vm.availabilityIsPassed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if vm.nicknameError == .nameIsUsed {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Error description under text field
            HStack {
                Text(vm.nicknameError.rawValue)
                    .padding(.top, 5)
                    .font(.caption)
                    .foregroundColor(vm.nicknameError == .none ? .secondary : .red)
                Spacer(minLength: 0)
            }
        }
    }
    
    // First name text field
    private var firstNamePart: some View {
        VStack(spacing: 0) {
            
            // Text field title
            HStack {
                Text("First name:")
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .font(.callout)
                TextField("", text: $vm.firstNameTextField)
                    .autocorrectionDisabled(true)
                    .textContentType(.givenName)
                    .keyboardType(.asciiCapable)
                    .onReceive(Just(vm.firstNameTextField)) { _ in
                        if vm.firstNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                            vm.firstNameTextField = String(vm.firstNameTextField.prefix(Limits.nameAndLastNameSymbolsLimit))
                        }
                    }
            }
            
            // Error description under text field
            HStack {
                Text(vm.firstNameError.rawValue)
                    .padding(.top, 5)
                    .font(.caption)
                    .foregroundColor(vm.firstNameError == .none ? .secondary : .red)
                
                Spacer(minLength: 0)
            }
        }
    }
    
    private var lastNamePart: some View {
        VStack(spacing: 0) {
            
            // Text field title
            HStack {
                Text("Last name:")
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .font(.callout)
                TextField("", text: $vm.lastNameTextField)
                    .autocorrectionDisabled(true)
                    .textContentType(.familyName)
                    .keyboardType(.asciiCapable)
                    .onReceive(Just(vm.lastNameTextField)) { _ in
                        if vm.lastNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                            vm.lastNameTextField = String(vm.lastNameTextField.prefix(Limits.nameAndLastNameSymbolsLimit))
                        }
                    }
            }
            
            // Error description under text field
            HStack {
                Text(vm.lastNameError.rawValue)
                    .padding(.top, 5)
                    .font(.caption)
                    .foregroundColor(vm.lastNameError == .none ? .secondary : .red)
                Spacer(minLength: 0)
            }
        }
    }
}






struct PersonalInfoPage_Previews: PreviewProvider {
    static private let id = CKRecord.ID(recordName: "7C21B420-2449-22D0-1F26-387A189663EA")
    
    static var previews: some View {
        NavigationStack {
            PersonalInfoPage(id: id)
        }
    }
}
