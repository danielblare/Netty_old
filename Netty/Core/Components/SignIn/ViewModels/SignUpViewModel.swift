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
    
    init() {
        // Starting page
        registrationLevel = .password
        
        // Checking whether user is more than 18 y.o.
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        birthDate = endingDate
        dateRangeFor18yearsOld = startingDate...endingDate
        
        addSubscribers(for: registrationLevel)
    }

    /// Registration progress
    enum RegistrationLevel {
        case name, email, nickname, password
    }
     
    /// Error connected with nickname entering
    enum NicknameError: String {
        case nameIsUsed = "Name is already used"
        case length = "Enter 3 or more symbols"
        case space = "Nickname contains unacceptable characters"
        case none = ""
    }
    
    // Name page
    private let nameAndLastNameSymbolsLimit: Int = 35
    @Published var firstNameTextField: String = "" {
        didSet {
            if firstNameTextField.count > nameAndLastNameSymbolsLimit {
                firstNameTextField = firstNameTextField.truncated(limit: nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var lastNameTextField: String = "" {
        didSet {
            if lastNameTextField.count > nameAndLastNameSymbolsLimit {
                lastNameTextField = lastNameTextField.truncated(limit: nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    var birthDate: Date
    var dateRangeFor18yearsOld: ClosedRange<Date>
    
    // Email page
    private let emailSymbolsLimit: Int = 64
    @Published var emailTextField: String = "" {
        didSet {
            if emailTextField.count > emailSymbolsLimit {
                emailTextField = emailTextField.truncated(limit: emailSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    
    // Nickname page
    private let nicknameSymbolsLimit: Int = 20
    @Published var nicknameTextField: String = "" {
        didSet {
            if nicknameTextField.count > nicknameSymbolsLimit {
                nicknameTextField = nicknameTextField.truncated(limit: nicknameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var nicknameError: NicknameError = .none
    @Published var nicknameIsChecking: Bool = false // Progress view
    @Published var availabilityIsPassed: Bool = false
    private var checkTask = Task{}

    // Password page
    private let passwordSymbolsLimit: Int = 23
    @Published var passwordField: String = "" {
        didSet {
            if passwordField.count > passwordSymbolsLimit {
                passwordField = passwordField.truncated(limit: passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordConfirmField: String = "" {
        didSet {
            if passwordConfirmField.count > passwordSymbolsLimit {
                passwordConfirmField = passwordConfirmField.truncated(limit: passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordMessage: PasswordWarningMessage = .short
    
    
    // Universal values
    @Published var nextButtonIsDisabled: Bool = true
    var transitionForward: Bool = true
    
    // Page number
    @Published var registrationLevel: RegistrationLevel
    
    // Cancellables publishers
    private var cancellables = Set<AnyCancellable>()
    
    /// Changes registration level forward, controls transition, disables next button, removes all old cancellables and adds new ones
    func moveToTheNextRegistrationLevel() {
        transitionForward = true
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.registrationLevel = self.nextRegistrationLevel()
                self.nextButtonIsDisabled = true
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
                self.nextButtonIsDisabled = false
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
                        } else if returnedValue.containsUnacceptableSymbols() {
                            self.nicknameError = .space
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
            
            
        case .password:
            
            let sharedPublisher = $passwordField
                .combineLatest($passwordConfirmField)
                .share()
            
            sharedPublisher
                .debounce(for: 0.7, scheduler: DispatchQueue.main)
                .filter({ password, _ in
                    password.count >= 8
                })
                .map(mapPasswords)
                .sink(receiveValue: { [weak self] passed, message in
                    if passed {
                        self?.nextButtonIsDisabled = false
                    }
                    withAnimation(.easeOut(duration: 0.3)) {
                        self?.passwordMessage = message
                    }
                })
                .store(in: &cancellables)
            
            sharedPublisher
                .filter( { _, _ in !self.nextButtonIsDisabled })
                .sink { [weak self] _, _ in
                    self?.nextButtonIsDisabled = true
                }
                .store(in: &cancellables)
        }
    }
    
    /// Returnes bool and PasswordWarningMessage where bool is true if password passed check and equals confirmation field
    private func mapPasswords(_ password: String, _ confirmation: String) -> (Bool, PasswordWarningMessage) {
        if password.count < 8 { return (false, .short) } else {
            if password.containsUnacceptableSymbols() { return (false, .unacceptableSymbols) } else {
                var uniqueSpecialSymbols: [String] = []
                var uniqueCapitalLetters: [String] = []
                var uniqueLowercasedLetters: [String] = []
                var uniqueNumbers: [String] = []
                
                
                
                for char in password {
                    if char.existsInSet(of: String.specialSymbols) {
                        uniqueSpecialSymbols.append("\(char)")
                    }
                    if char.existsInSet(of: String.capitalLetters) {
                        uniqueCapitalLetters.append("\(char)")
                    }
                    if char.existsInSet(of: String.lowercasedLetters) {
                        uniqueLowercasedLetters.append("\(char)")
                    }
                    if char.existsInSet(of: String.numbers) {
                        uniqueNumbers.append("\(char)")
                    }
                }
                
                uniqueSpecialSymbols = Array(Set(uniqueSpecialSymbols))
                uniqueCapitalLetters = Array(Set(uniqueCapitalLetters))
                uniqueLowercasedLetters = Array(Set(uniqueLowercasedLetters))
                uniqueNumbers = Array(Set(uniqueNumbers))
                if password.count > 12 && password.containsLowercasedLetters() && password.containsNumbers() && password.containsCapitalLetters() && password.containsSpecialSymbols() && uniqueSpecialSymbols.count >= 2 &&
                    (uniqueNumbers.count >= 3 || uniqueLowercasedLetters.count >= 3 || uniqueCapitalLetters.count >= 3) {
                    return (password == confirmation, .veryStrong)
                } else if password.count > 10 && password.containsLowercasedLetters() && password.containsNumbers() && (password.containsCapitalLetters() || password.containsSpecialSymbols()) && (uniqueCapitalLetters.count >= 3 || uniqueSpecialSymbols.count >= 2) && (uniqueNumbers.count >= 3 || uniqueLowercasedLetters.count >= 3) {
                    return (password == confirmation, .strong)
                } else if password.containsLowercasedLetters() && password.containsNumbers() && password.containsCapitalLetters() && uniqueLowercasedLetters.count >= 2  && (uniqueNumbers.count >= 2 || uniqueCapitalLetters.count >= 2) {
                    return (password == confirmation, .medium)
                } else if password.containsNumbers() && (password.containsLowercasedLetters() || password.containsCapitalLetters()) {
                    return (password == confirmation, .weak)
                } else {
                    return (false, .numbersAndLetters)
                }
            }
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
            return .password
        case .password:
            return .password
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
        case .password:
            return .nickname
        }
    }
}
