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
    @Published var availabilityIsPassed: Bool = false
    private var checkTask = Task{}

    
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
                .filter({ ($0.containsOnlyLetters() && $0.count >= 3) && ($1.containsOnlyLetters() && $1.count >= 3) })
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = false
                }
                .store(in: &cancellables)
            
            // Disables next button immidiatly with any field change
            sharedPublisher
                .filter({ _ in !self.nextButtonIsDisabled })
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = true
                }
                .store(in: &cancellables)
            
        case .email:
            
            let sharedPublisher = $emailTextField
                .share()
            
            // After 0.5 second of inactivity checks whether email is correct
            sharedPublisher
                .removeDuplicates()
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .filter({ $0.isValidEmail() })
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = false
                }
                .store(in: &cancellables)
            
            // Disables next button immidiatly with any field change
            sharedPublisher
                .removeDuplicates()
                .filter({ _ in !self.nextButtonIsDisabled })
                .sink { [weak self] _ in
                    self?.nextButtonIsDisabled = true
                }
                .store(in: &cancellables)
            
        case .nickname:
            
            let sharedPublisher = $nicknameTextField
                .share()
            
            let manager = AvailabilityCheckManager.instance
            
            // After 0.5 second of inactivity checks whether nickname is at least 3 symbols long and available
            sharedPublisher
                .removeDuplicates()
                .drop(while: { $0.count == 0 })
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .sink { [weak self] returnedValue in
                    if let self = self {
                        self.availabilityIsPassed = false
                        if returnedValue.count < 3 {
                            self.nicknameError = .length
                        } else {
                            self.nicknameIsChecking = true
                            self.checkTask = Task {
                                let check = await manager.checkAvailability(for: self.nicknameTextField)
                                if !self.checkTask.isCancelled {
                                    await MainActor.run(body: {
                                        if check {
                                            self.availabilityIsPassed = true
                                            HapticManager.instance.notification(of: .success)
                                            self.nextButtonIsDisabled = false
                                        } else {
                                            self.nicknameError = .nameIsUsed
                                            HapticManager.instance.notification(of: .error)
                                        }
                                        self.nicknameIsChecking = false
                                    })
                                }
                            }
                        }
                    }
                }
                .store(in: &cancellables)
            
            // Disables next button and stops availability checking task immidiatly with any field change
            sharedPublisher
                .removeDuplicates()
                .drop(while: { $0.count == 0 })
                .filter({ _ in !self.checkTask.isCancelled || self.nicknameIsChecking || !self.nextButtonIsDisabled || self.nicknameError != .none || self.availabilityIsPassed })
                .sink { [weak self] returnedValue in
                    if let self = self {
                        self.checkTask.cancel()
                        self.nicknameIsChecking = false
                        self.nextButtonIsDisabled = true
                        self.nicknameError = .none
                        self.availabilityIsPassed = false
                    }
                }
                .store(in: &cancellables)
        }
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
