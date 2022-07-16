//
//  SignUpViewModel.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation
import SwiftUI
import Combine

class SignUpViewModel: ObservableObject {
    
    enum RegistrationLevel {
        case name, email
    }
    
    // First page
    @Published var firstNameTextField: String = ""
    @Published var lastNameTextField: String = ""
    var birthDate: Date
    var dateRangeFor18yearsOld: ClosedRange<Date>
    
    // Second page
    @Published var emailTextField: String = ""
    @Published var nicknameTextField: String = ""
    
    
    @Published var showNextButton: Bool = false
    
    // Page number
    @Published var registrationLevel: RegistrationLevel
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        registrationLevel = .email
        
        // Checking whether user is more than 18 y.o.
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        birthDate = endingDate
        dateRangeFor18yearsOld = startingDate...endingDate
        
        addSubscribers(for: registrationLevel)
        print("ViewModel INIT")
    }
    
    func moveToTheNextRegistrationLevel() {
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.registrationLevel = self.nextRegistrationLevel()
                self.showNextButton = false
                
                print("Before \(self.cancellables.description)")
                if let cancellable = self.cancellables.first {
                    cancellable.cancel()
                    self.cancellables.removeAll()
                }
                print("After \(self.cancellables.description)")
                
                self.addSubscribers(for: self.registrationLevel)
            }
        }
    }

    private func addSubscribers(for level: RegistrationLevel) {
        switch level {
        case .name:
            $firstNameTextField
                .combineLatest($lastNameTextField)
                .receive(on: DispatchQueue.main)
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .map(mappingFirstAndLastName)
                .sink { [weak self] check in
                    self?.showNextButton = check
                }
                .store(in: &cancellables)
        case .email:
            print("Case 2")
        }
    }
    
    private func nextRegistrationLevel() -> RegistrationLevel {
        switch registrationLevel {
        case .name:
            return .email
        case .email:
            return .email
        }
    }
    
    private func mappingFirstAndLastName(_ firstName: String, _ lastName: String) -> Bool {
        print("Mapping")
        return (firstName.containsOnlyLetters() && firstName.count >= 3) && (lastName.containsOnlyLetters() && lastName.count >= 3)
    }
}
