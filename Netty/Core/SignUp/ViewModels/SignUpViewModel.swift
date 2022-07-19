//
//  SignUpViewModel.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation
import SwiftUI
import Combine
import MessageUI

class SignUpViewModel: ObservableObject {
    
    init() {
        // Checking whether user is more than 18 y.o.
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        birthDate = endingDate
        dateRangeFor18yearsOld = startingDate...endingDate
        
        addSubscribers()
    }
    
    /// Error connected with nickname entering
    enum NicknameError: String {
        case nameIsUsed = "Name is already used"
        case length = "Enter 3 or more symbols"
        case space = "Nickname contains unacceptable characters"
        case none = ""
    }
    
    enum EmailButtonText: String {
        case send = "Send code"
        case again = "Send again"
        case verificated = ""
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
    @Published var nameNextButtonDisabled: Bool = true
    
    // Email page
    private let emailSymbolsLimit: Int = 64
    @Published var emailTextField: String = "" {
        didSet {
            if emailTextField.count > emailSymbolsLimit {
                emailTextField = emailTextField.truncated(limit: emailSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    private var savedEmail: String = ""
    private var oneTimePasscode: String? = nil
    @Published var showAlert: Bool = false
    private var alertError: Error? = nil
    @Published var emailButtonDisabled: Bool = true
    @Published var emailButtonText: EmailButtonText = .send
    @Published var emailTextFieldIsDisabled: Bool = false
    @Published var emailNextButtonDisabled: Bool = true
    
    // Timer
    @Published var showTimer: Bool = false
    @Published var timeRemaining: String = ""
    
    
    @Published var codeTextField: String = "" {
        didSet {
            if codeTextField.containsSomethingExceptNumbers() && !oldValue.containsSomethingExceptNumbers() {
                codeTextField = oldValue
            }
            if codeTextField.count > 6 {
                codeTextField = codeTextField.truncated(limit: 6, position: .tail, leader: "")
            }
        }
    }
    @Published var showCodeTextField: Bool = false
    @Published var codeCheckPassed: Bool = false
    @Published var confirmButtonDisabeld: Bool = true
    @Published var showSuccedStatusIcon: Bool = false
    @Published var showFailStatusIcon: Bool = false
    
    
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
    @Published var nicknameNextButtonDisabled: Bool = true
    
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
    @Published var passwordNextButtonDisabled: Bool = true
    
    // Cancellables publishers
    private var cancellables = Set<AnyCancellable>()
    
    func emailButtonPressed() async {
        switch emailButtonText {
        case .send:
            savedEmail = emailTextField
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.09)) {
                    startTimerFor(seconds: 10)
                    self.emailButtonDisabled = true
                    self.showCodeTextField = true
                }
                emailButtonText = .again
            }
        case .again:
            savedEmail = emailTextField
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.09)) {
                    startTimerFor(seconds: 59)
                    self.emailButtonDisabled = true
                }
            }
        case .verificated: break
        }
        
        do {
            try await sendEmail()
        } catch {
            alertError = error
            showAlert = true
        }
    }
    
    private var futureDate = Date()
    private var cancellablesTimer = Set<AnyCancellable>()
    
    private func startTimerFor(seconds: Int) {
        futureDate = Calendar.current.date(byAdding: .second, value: seconds + 1, to: Date()) ?? Date()
        let remaining = Calendar.current.dateComponents([.minute, .second], from: Date(), to: self.futureDate)
        let minute = remaining.minute ?? 0
        let second = remaining.second ?? 0
        if second >= 10 {
            timeRemaining = "\(minute):\(second)"
        } else {
            timeRemaining = "\(minute):0\(second)"
        }
        showTimer = true
        Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
            .sink { _ in
                let remaining = Calendar.current.dateComponents([.minute, .second], from: Date(), to: self.futureDate)
                let minute = remaining.minute ?? 0
                let second = remaining.second ?? 0
                if second <= 0 && minute <= 0 {
                    self.showTimer = false
                    self.cancellablesTimer.first?.cancel()
                } else {
                    if second >= 10 {
                        self.timeRemaining = "\(minute):\(second)"
                    } else {
                        self.timeRemaining = "\(minute):0\(second)"
                    }
                }
            }
            .store(in: &cancellablesTimer)
        
        
    }
    
    func getAlert() -> Alert {
        Alert(
            title: Text("Error sending e-mail"),
            message: Text(alertError?.localizedDescription ?? ""),
            dismissButton: .cancel()
        )
    }
    
    private func sendEmail() async throws {
        
        oneTimePasscode = String.generateOneTimeCode()
        
        let to = savedEmail
        let subject = "E-mail Confirmation"
        let type = "text/HTML"
        let text = "<h3>Welcome to Netty, \(firstNameTextField) \(lastNameTextField)!</h3><br /><br />Your confirmation code is <b>\(oneTimePasscode ?? "ErRoR")</b>"
        
        let _ = try await EmailSendManager.instance.sendEmail(to: to, subject: subject, type: type, text: text)
    }
    
    func confirmButtonPressed() {
        withAnimation(.easeInOut(duration: 0.09)) {
            if codeTextField == oneTimePasscode {
                showTimer = false
                emailButtonText = .verificated
                emailTextField = savedEmail
                emailTextFieldIsDisabled = true
                withAnimation(.easeInOut.delay(0.5)) {
                    codeCheckPassed = true
                    showCodeTextField = false
                    emailNextButtonDisabled = false
                }
                withAnimation(.easeInOut.delay(1)) {
                    showSuccedStatusIcon = true
                    HapticManager.instance.notification(of: .success)
                }
            } else {
                confirmButtonDisabeld = true
                showFailStatusIcon = true
                HapticManager.instance.notification(of: .error)
            }
        }
    }
    
    /// Adding subscribers depending on current registration level
    private func addSubscribers() {
        let sharedFirstNamePublisher = $firstNameTextField
            .combineLatest($lastNameTextField)
            .share()
        
        // After 0.5 second of inactivity checks whether first and last names are correct
        sharedFirstNamePublisher
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .filter({ ($0.containsOnlyLetters() && $0.count >= 3) && ($1.containsOnlyLetters() && $1.count >= 3) })
            .sink { [weak self] _ in
                self?.nameNextButtonDisabled = false
            }
            .store(in: &cancellables)
        
        // Disables next button immidiatly with any field change
        sharedFirstNamePublisher
            .filter({ _ in !self.nameNextButtonDisabled })
            .sink { [weak self] _ in
                self?.nameNextButtonDisabled = true
            }
            .store(in: &cancellables)
        
        
        let sharedEmailPublisher = $emailTextField
            .share()
        
        let sharedCodePublisher = $codeTextField
            .share()
        
        // After 0.5 second of inactivity checks whether email is correct
        sharedEmailPublisher
            .combineLatest($showTimer)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .filter({ email, _ in email.isValidEmail() && !self.showTimer })
            .sink { [weak self] _ in
                self?.emailButtonDisabled = false
            }
            .store(in: &cancellables)
        
        // Disables next button immidiatly with any field change
        sharedEmailPublisher
            .removeDuplicates()
            .filter({ _ in !self.emailButtonDisabled })
            .sink { [weak self] _ in
                self?.emailButtonDisabled = true
            }
            .store(in: &cancellables)
        
        sharedCodePublisher
            .removeDuplicates()
            .map({ $0.count == 6 })
            .sink { [weak self] receivedValue in
                self?.confirmButtonDisabeld = !receivedValue
            }
            .store(in: &cancellables)
        
        sharedCodePublisher
            .removeDuplicates()
            .filter({ _ in self.showFailStatusIcon })
            .sink { [weak self] _ in
                self?.showFailStatusIcon = false
            }
            .store(in: &cancellables)
        
        
        let sharedNicknamePublisher = $nicknameTextField
            .share()
        
        let manager = AvailabilityCheckManager.instance
        
        // After 0.5 second of inactivity checks whether nickname is at least 3 symbols long and available
        sharedNicknamePublisher
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
                                        self.nicknameNextButtonDisabled = false
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
        sharedNicknamePublisher
            .removeDuplicates()
            .drop(while: { $0.count == 0 })
            .filter({ _ in !self.checkTask.isCancelled || self.nicknameIsChecking || !self.nicknameNextButtonDisabled || self.nicknameError != .none || self.availabilityIsPassed })
            .sink { [weak self] returnedValue in
                if let self = self {
                    self.checkTask.cancel()
                    self.nicknameIsChecking = false
                    self.nicknameNextButtonDisabled = true
                    self.nicknameError = .none
                    self.availabilityIsPassed = false
                }
            }
            .store(in: &cancellables)
        
        
        let sharedPasswordPublisher = $passwordField
            .combineLatest($passwordConfirmField)
            .share()
        
        sharedPasswordPublisher
            .debounce(for: 0.7, scheduler: DispatchQueue.main)
            .filter({ password, _ in
                password.count >= 8
            })
            .map(mapPasswords)
            .sink(receiveValue: { [weak self] passed, message in
                if passed {
                    self?.passwordNextButtonDisabled = false
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.passwordMessage = message
                }
            })
            .store(in: &cancellables)
        
        sharedPasswordPublisher
            .filter( { _, _ in !self.passwordNextButtonDisabled })
            .sink { [weak self] _, _ in
                self?.passwordNextButtonDisabled = true
            }
            .store(in: &cancellables)
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
    
}
