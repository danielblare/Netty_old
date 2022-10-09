//
//  SignUpViewModel.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation
import SwiftUI
import Combine
import CloudKit

struct Limits {
    static let nameAndLastNameSymbolsLimit: Int = 35
    static let emailSymbolsLimit: Int = 64
    static let nicknameSymbolsLimit: Int = 20
    static let passwordSymbolsLimit: Int = 23

}

class SignUpViewModel: ObservableObject {
    
    init(userRecordId: Binding<CKRecord.ID?>, path: Binding<NavigationPath>) {
        self._userRecordId = userRecordId
        self._path = path
        
        // Checking whether user is more than 18 y.o.
        let startingDate: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let endingDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        birthDate = endingDate
        dateRangeFor18yearsOld = startingDate...endingDate
        
        addSubscribers()
    }
    
    @Binding var path: NavigationPath
    @Binding var userRecordId: CKRecord.ID?
        
    enum EmailButtonText: String {
        case send = "Send code"
        case again = "Send again"
        case verificated = ""
    }
    

    /// Error connected with nickname entering
    enum NicknameError: String {
        case nameIsUsed = "Nickname is already used"
        case length = "Enter 3 or more symbols"
        case space = "Nickname contains unacceptable characters"
        case none = ""
    }

    // Name page
    @Published var firstNameTextField: String = "" {
        didSet {
            if firstNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                firstNameTextField = firstNameTextField.truncated(limit: Limits.nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var lastNameTextField: String = "" {
        didSet {
            if lastNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                lastNameTextField = lastNameTextField.truncated(limit: Limits.nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    var birthDate: Date
    var dateRangeFor18yearsOld: ClosedRange<Date>
    @Published var nameNextButtonDisabled: Bool = true
    
    // Email page
    @Published var emailTextField: String = "" {
        didSet {
            if emailTextField.count > Limits.emailSymbolsLimit {
                emailTextField = emailTextField.truncated(limit: Limits.emailSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    private var savedEmail: String = ""
    private var oneTimePasscode: String? = nil
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
    @Published var nicknameTextField: String = "" {
        didSet {
            if nicknameTextField.count > Limits.nicknameSymbolsLimit {
                nicknameTextField = nicknameTextField.truncated(limit: Limits.nicknameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var nicknameError: NicknameError = .none
    @Published var nicknameIsChecking: Bool = false // Progress view
    @Published var availabilityIsPassed: Bool = false
    private var checkTask = Task{}
    @Published var nicknameNextButtonDisabled: Bool = true
    
    // Password page
    @Published var passwordField: String = "" {
        didSet {
            if passwordField.count > Limits.passwordSymbolsLimit {
                passwordField = passwordField.truncated(limit: Limits.passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordConfirmField: String = "" {
        didSet {
            if passwordConfirmField.count > Limits.passwordSymbolsLimit {
                passwordConfirmField = passwordConfirmField.truncated(limit: Limits.passwordSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    @Published var passwordMessage: PasswordWarningMessage = .short
    @Published var passwordNextButtonDisabled: Bool = true
    @Published var creatingAccountIsLoading: Bool = false
    @Published var showDontMatchError: Bool = false
    
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
        
    
    // Cancellables publishers
    private var cancellables = Set<AnyCancellable>()
    
    func emailButtonPressed() async {
        
        savedEmail = emailTextField.lowercased()
        
        switch await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .usersRecordType, withField: .emailRecordField, equalTo: savedEmail) {
        case .success(let exist):
            if !exist {
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
                case .verificated: break
                }
                
                do {
                    try await self.sendEmail()
                } catch {
                    self.showAlert(title: "Error while sending e-mail", message: error.localizedDescription)
                }
            } else {
                showAlert(title: "Error", message: "Account with this e-mail already exists")
            }
        case .failure(let failure):
            showAlert(title: "Server error", message: failure.localizedDescription)
        }
        
        
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
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
    
    private func sendEmail() async throws {
        
        oneTimePasscode = String.generateOneTimeCode()
        
        let to = savedEmail
        let subject = "E-mail Confirmation"
        let type = "text/HTML"
        let text = "<h3>Welcome to Netty, \(firstNameTextField) \(lastNameTextField)!</h3><br /><br />Your confirmation code is <b>\(oneTimePasscode ?? "ErRoR")</b>"
        
        let _ = try await EmailSendManager.instance.sendEmail(to: to, subject: subject, type: type, text: text)
    }
    
    func createAccount() async {
        await MainActor.run(body: {
            creatingAccountIsLoading = true
        })
        
        let firstName = firstNameTextField
        let lastName = lastNameTextField
        let dateOfBirth = birthDate
        let nickname = nicknameTextField
        let email = savedEmail
        let password = passwordField
        
        let newUser = CKRecord(recordType: .usersRecordType)
        newUser[.firstNameRecordField] = firstName
        newUser[.lastNameRecordField] = lastName
        newUser[.dateOfBirthRecordField] = dateOfBirth
        newUser[.emailRecordField] = email
        newUser[.nicknameRecordField] = nickname
        newUser[.passwordRecordField] = password
        newUser[.avatarRecordField] = nil
        newUser[.loggedInDeviceRecordField] = ""
        
        let result = await CloudKitManager.instance.saveRecordToPublicDatabase(newUser)
        await MainActor.run(body: {
            creatingAccountIsLoading = false
            switch result {
            case .success(let returnedRecord):
                Task {
                    await LogInAndOutManager.instance.addLoggedInDevice(for: returnedRecord.recordID)
                }
                withAnimation(.easeInOut(duration: 0.5)) {
                    path = NavigationPath()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.userRecordId = returnedRecord.recordID
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while creating an account", message: error.localizedDescription)
            }
        })
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
    
    func checkAvailability(for nickname: String) async -> Bool {
        
        switch await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .usersRecordType, withField: .nicknameRecordField, equalTo: nickname) {
        case .success(let exist):
            return !exist
        case .failure(let failure):
            showAlert(title: "Server error", message: failure.localizedDescription)
            return false
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
            .filter({ ($0.containsOnlyLetters() && $0.count >= 2) && ($1.containsOnlyLetters() && $1.count >= 2) })
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
                            let check = await self.checkAvailability(for: self.nicknameTextField)
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
            .debounce(for: 2.0, scheduler: DispatchQueue.main)
            .filter({ $0 != $1 })
            .sink { [weak self] _, _ in
                self?.showDontMatchError = true
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
            .filter( { _, _ in !self.passwordNextButtonDisabled || self.showDontMatchError })
            .sink { [weak self] _, _ in
                self?.showDontMatchError = false
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
