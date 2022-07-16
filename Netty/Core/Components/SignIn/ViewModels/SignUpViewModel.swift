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
    
    /// Registration progress
    enum RegistrationLevel {
        case name, email, nickname
    }
     
    /// Error connected with nickname entering
    enum NicknameError: String {
        case nameIsUsed = "Name is already used"
        case length = "Enter 3 or more symbols"
        case none = ""
    }
    
    // First page
    @Published var firstNameTextField: String = ""
    @Published var lastNameTextField: String = ""
    var birthDate: Date
    var dateRangeFor18yearsOld: ClosedRange<Date>
    
    // Second page
    @Published var emailTextField: String = ""
    
    // Third page
    @Published var nicknameTextField: String = ""
    @Published var nicknameError: NicknameError = .none
    @Published var nicknameIsChecking: Bool = false // Progress view
    @Published var checkButtonIsDisabled: Bool = true
    @Published var availabilityIsPassed: Bool = false
    @Published var nicknameFieldIsDisabled: Bool = false
    
    // Universal values
    @Published var nextButtonIsDisabled: Bool = true
    var transitionForward: Bool = true
    
    // Page number
    @Published var registrationLevel: RegistrationLevel
    
    // Cancellables publishers
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Starting page
        registrationLevel = .name
        
        // Checking whether user is more than 18 y.o.
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        birthDate = endingDate
        dateRangeFor18yearsOld = startingDate...endingDate
        
        addSubscribers(for: registrationLevel)
    }
    
    /// Changes registration level forward, controls transition, disables next button, removes all old cancellables and adds new ones
    func moveToTheNextRegistrationLevel() {
        transitionForward = true
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.registrationLevel = self.nextRegistrationLevel()
                self.nextButtonIsDisabled = true
                
                self.cancellables.forEach { cancellable in
                    cancellable.cancel()
                }
                self.cancellables.removeAll()
                
                self.addSubscribers(for: self.registrationLevel)
            }
        }
    }
    
    /// Changes registration level backward, controls transition, disables next button, removes all old cancellables and adds new ones
    func moveToThePreviousRegistrationLevel() {
        transitionForward = false
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.registrationLevel = self.previousRegistrationLevel()
                self.nextButtonIsDisabled = true
                
                self.cancellables.forEach { cancellable in
                    cancellable.cancel()
                }
                self.cancellables.removeAll()

                self.addSubscribers(for: self.registrationLevel)
            }
        }
    }

    /// Adding subscribers depending on current registration level
    private func addSubscribers(for level: RegistrationLevel) {
        switch level {
        case .name:
            
            let sharedPublisher = $firstNameTextField
                .combineLatest($lastNameTextField)
                .share()
            
            // After 0.5 second of inactivity checks whether first and last names are correct
            sharedPublisher
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .map({ ($0.containsOnlyLetters() && $0.count >= 3) && ($1.containsOnlyLetters() && $1.count >= 3) })
                .sink { [weak self] receivedValue in
                    self?.nextButtonIsDisabled = !receivedValue
                }
                .store(in: &cancellables)
            
            // Disables next button immidiatly with any field change
            sharedPublisher
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = true
                }
                .store(in: &cancellables)
            
        case .email:
            
            let sharedPublisher = $emailTextField
                .share()
            
            // After 0.5 second of inactivity checks whether email is correct
            sharedPublisher
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .map { email in
                    email.isValidEmail()
                }
                .sink { [weak self] receivedValue in
                    self?.nextButtonIsDisabled = !receivedValue
                }
                .store(in: &cancellables)
            
            // Disables next button immidiatly with any field change
            sharedPublisher
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = true
                }
                .store(in: &cancellables)
            
        case .nickname:
            
            let sharedPublisher = $nicknameTextField
                .share()
            
            // After 0.5 second of inactivity checks whether nickname is at least 3 symbols long and unlocks check availability button
            sharedPublisher
                .dropFirst(3)
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .sink { [weak self] reveivedValue in
                    if reveivedValue.count < 3 {
                        self?.nicknameError = NicknameError.length
                    } else {
                        if let self = self,
                           !self.nicknameIsChecking {
                            self.checkButtonIsDisabled = false
                        }
                    }
                }
                .store(in: &cancellables)

            // Disables next and check buttons immidiatly with any field change
            sharedPublisher
                .sink { [weak self] _ in
                    if let self = self {
                        self.checkButtonIsDisabled = true
                        self.nextButtonIsDisabled = true
                        self.availabilityIsPassed = false
                        self.nicknameError = .none
                    }
                }
                .store(in: &cancellables)

        }
    }
    
    /// Checks availability of the nickname
    func checkAvailability(of nickname: String) async {
        await MainActor.run(body: {
            nicknameFieldIsDisabled = true
            checkButtonIsDisabled = true
            nicknameIsChecking = true
        })
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Delay simulation
        
        await MainActor.run(body: {
            nicknameFieldIsDisabled = false
            nicknameIsChecking = false

            if nickname.hasPrefix("stuffed") { // Logic simulation
                availabilityIsPassed = true
                HapticManager.instance.notification(of: .success)
                nextButtonIsDisabled = false
            } else {
                nicknameError = NicknameError.nameIsUsed
                HapticManager.instance.notification(of: .error)
            }
        })
    }
    
    /// Returns next registration level
    private func nextRegistrationLevel() -> RegistrationLevel {
        switch registrationLevel {
        case .name:
            return .email
        case .email:
            return .nickname
        case .nickname:
            return .nickname
        }
    }

    /// Returns previous registration level
    private func previousRegistrationLevel() -> RegistrationLevel {
        switch registrationLevel {
        case .name:
            return .name
        case .email:
            return .name
        case .nickname:
            return .email
        }
    }
}
