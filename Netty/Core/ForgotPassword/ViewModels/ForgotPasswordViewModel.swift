//
//  ForgotPasswordViewModel.swift
//  Netty
//
//  Created by Danny on 9/13/22.
//

import SwiftUI
import CloudKit
import Combine


class ForgotPasswordViewModel: ObservableObject {
        
    init() {
        addSubscribers()
    }
                
    // Email page
    private let emailSymbolsLimit: Int = 64
    @Published var emailTextField: String = ""
    private var savedEmail: String = ""
    private var oneTimePasscode: String? = nil
    @Published var emailButtonDisabled: Bool = true
    @Published var emailButtonText: EmailButtonText = .send
    @Published var emailTextFieldIsDisabled: Bool = false
    @Published var emailNextButtonDisabled: Bool = true
    
    // Timer
    @Published var showTimer: Bool = false
    @Published var timeRemaining: String = ""
    
    // One time code
    @Published var codeTextField: String = ""
    @Published var showCodeTextField: Bool = false
    @Published var codeCheckPassed: Bool = false
    @Published var confirmButtonDisabled: Bool = true
    @Published var showSucceedStatusIcon: Bool = false
    @Published var showFailStatusIcon: Bool = false
    
    
    // Password page
    private let passwordSymbolsLimit: Int = 23
    @Published var passwordField: String = ""
    @Published var passwordConfirmField: String = ""
    @Published var passwordMessage: PasswordWarningMessage = .short
    @Published var passwordNextButtonDisabled: Bool = true
    @Published var changingPasswordIsLoading: Bool = false
    @Published var showMatchingError: Bool = false
    
    // Alert
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    // Cancellable publishers
    private var cancellables = Set<AnyCancellable>()
    private var cancellablesForTimer = Set<AnyCancellable>()

    // Future date to set up time out after email sending
    private var futureDate = Date()
    
    /// Perform action if email button pressed
    func emailButtonPressed() async {
        
        savedEmail = emailTextField.lowercased()
        
        switch await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .usersRecordType, withField: .emailRecordField, equalTo: savedEmail) {
        case .success(let exist):
            if exist {
                switch self.emailButtonText {
                case .send:
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.09)) {
                            self.startTimerFor(seconds: 10)
                            self.emailButtonDisabled = true
                            self.showCodeTextField = true
                        }
                        self.emailButtonText = .again
                    }
                case .again:
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.09)) {
                            self.startTimerFor(seconds: 59)
                            self.emailButtonDisabled = true
                        }
                    }
                case .verified: break
                }
                
                do {
                    try await self.sendEmail()
                } catch {
                    showAlert(title: "Error while sending e-mail", message: error.localizedDescription)
                }
            } else {
                showAlert(title: "Error", message: "Account with this e-mail does not exist")
            }
        case .failure(let failure):
            showAlert(title: "Server error", message: failure.localizedDescription)
        }
        
        
    }
    
    /// Shows alert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    /// Starts timer for definite time
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
                    self.cancellablesForTimer.first?.cancel()
                } else {
                    if second >= 10 {
                        self.timeRemaining = "\(minute):\(second)"
                    } else {
                        self.timeRemaining = "\(minute):0\(second)"
                    }
                }
            }
            .store(in: &cancellablesForTimer)
        
        
    }
    
    /// Sends email with verification code
    private func sendEmail() async throws {
        
        oneTimePasscode = String.generateOneTimeCode()
        
        let to = savedEmail
        let subject = "E-mail Verification"
        let type = "text/HTML"
        let text = "<h3>Password reset</h3><br /><br />Your confirmation code is <b>\(oneTimePasscode ?? "ErRoR")</b>"
        
        let _ = try await EmailSendManager.instance.sendEmail(to: to, subject: subject, type: type, text: text)
    }
        
    /// Performs actions if confirm button pressed
    func confirmButtonPressed() {
        withAnimation(.easeInOut(duration: 0.09)) {
            if codeTextField == oneTimePasscode {
                showTimer = false
                emailButtonText = .verified
                emailTextField = savedEmail
                emailTextFieldIsDisabled = true
                withAnimation(.easeInOut.delay(0.5)) {
                    codeCheckPassed = true
                    showCodeTextField = false
                    emailNextButtonDisabled = false
                }
                withAnimation(.easeInOut.delay(1)) {
                    showSucceedStatusIcon = true
                    HapticManager.instance.notification(of: .success)
                }
            } else {
                confirmButtonDisabled = true
                showFailStatusIcon = true
                HapticManager.instance.notification(of: .error)
            }
        }
    }
    
    /// Updates password
    func changePassword(prMode: Binding<PresentationMode>) async {
        await MainActor.run(body: {
            changingPasswordIsLoading = true
        })
        
        let newPassword = passwordField
        
        switch await CloudKitManager.instance.recordIdOfUser(withField: .emailRecordField, inRecordType: .usersRecordType, equalTo: savedEmail) {
        case .success(let recordId):
            if let recordId = recordId {
                let result = await CloudKitManager.instance.updateFieldForUserWith(recordId: recordId, field: .passwordRecordField, newData: newPassword)
                await MainActor.run {
                    changingPasswordIsLoading = false
                    switch result {
                    case .success(_):
                        prMode.wrappedValue.dismiss()
                        showAlert(title: "Password reset", message: "Your password has been successfully changed")
                    case .failure(let error):
                        self.showAlert(title: "Error while updating password", message: error.localizedDescription)
                    }
                }
            } else {
                await MainActor.run {
                    changingPasswordIsLoading = false
                }
                self.showAlert(title: "Error while finding user with this e-mail", message: "Contact support")
            }
        case .failure(let error):
            await MainActor.run {
                changingPasswordIsLoading = false
            }
            self.showAlert(title: "Error while finding user with this e-mail", message: error.localizedDescription)
        }

    }
            
    /// Subscribes on publishers
    private func addSubscribers() {
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
        
        // Disables next button immediately with any field change
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
                self?.confirmButtonDisabled = !receivedValue
            }
            .store(in: &cancellables)
        
        sharedCodePublisher
            .removeDuplicates()
            .filter({ _ in self.showFailStatusIcon })
            .sink { [weak self] _ in
                self?.showFailStatusIcon = false
            }
            .store(in: &cancellables)
        
        let sharedPasswordPublisher = $passwordField
            .combineLatest($passwordConfirmField)
            .share()
        
        sharedPasswordPublisher
            .debounce(for: 2.0, scheduler: DispatchQueue.main)
            .filter({ $0 != $1 })
            .sink { [weak self] _, _ in
                self?.showMatchingError = true
            }
            .store(in: &cancellables)
        
        sharedPasswordPublisher
            .debounce(for: 0.7, scheduler: DispatchQueue.main)
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
            .filter( { _, _ in !self.passwordNextButtonDisabled || self.showMatchingError })
            .sink { [weak self] _, _ in
                self?.showMatchingError = false
                self?.passwordNextButtonDisabled = true
            }
            .store(in: &cancellables)
    }
    
    /// Returns bool and PasswordWarningMessage where bool is true if password passed check and equals confirmation field
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
