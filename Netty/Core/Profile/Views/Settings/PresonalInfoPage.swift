//
//  PersonalInfoPage.swift
//  Netty
//
//  Created by Danny on 10/4/22.
//
import SwiftUI
import CloudKit

struct PersonalInfoPage: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm: PersonalInfoViewModel
    init(id: CKRecord.ID?) {
        _vm = .init(wrappedValue: PersonalInfoViewModel(id: id))
    }
    
    @State private var confirmationDialogIsPresented: Bool = false
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
        .toolbar { getToolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Are you sure you want to save changes?", isPresented: $confirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Save") {
                Task {
                    await vm.saveChanges()
                }
            }
        }
    }

    
    @ToolbarContentBuilder private func getToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                confirmationDialogIsPresented = true
            }
            .disabled(vm.saveButtonDisabled)
        }
    }
    
    private var dateOfBirthPart: some View {
        ZStack {
            DatePicker("Date of birth:", selection: $vm.dateOfBirthPicker, in: dateRange, displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundColor(.secondary)
                .font(.callout)
                .padding(.vertical, 2)
        }
    }
    
    private var nicknamePart: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Text("Nickname:")
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                            .font(.callout)
                        TextField("", text: $vm.nicknameTextField)
                            .autocorrectionDisabled(true)
                            .textContentType(.nickname)
                            .keyboardType(.asciiCapable)
                    }
                    HStack {
                        Spacer(minLength: 0)
                        
                        if vm.nicknameIsChecking {
                            ProgressView()
                        }
                    }
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
                HStack {
                    Text(vm.nicknameError.rawValue)
                        .padding(.top, 5)
                        .font(.caption)
                        .foregroundColor(vm.nicknameError == .none ? .secondary : .red)
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private var firstNamePart: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Text("First name:")
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                            .font(.callout)
                        TextField("", text: $vm.firstNameTextField)
                            .autocorrectionDisabled(true)
                            .textContentType(.givenName)
                            .keyboardType(.asciiCapable)
                    }
                }
                HStack {
                    Text(vm.firstNameError.rawValue)
                        .padding(.top, 5)
                        .font(.caption)
                        .foregroundColor(vm.firstNameError == .none ? .secondary : .red)
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private var lastNamePart: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Text("Last name:")
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                            .font(.callout)
                        TextField("", text: $vm.lastNameTextField)
                            .autocorrectionDisabled(true)
                            .textContentType(.familyName)
                            .keyboardType(.asciiCapable)
                    }
                }
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
}






struct PersonalInfoPage_Previews: PreviewProvider {
    static private let id = CKRecord.ID(recordName: "7C21B420-2449-22D0-1F26-387A189663EA")
    
    static var previews: some View {
        NavigationStack {
            PersonalInfoPage(id: id)
        }
    }
}
