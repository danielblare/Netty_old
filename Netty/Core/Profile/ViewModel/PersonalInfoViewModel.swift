//
//  PersonalInfoViewModel.swift
//  Netty
//
//  Created by Danny on 10/4/22.
//

import SwiftUI
import Combine
import CloudKit

class PersonalInfoViewModel: ObservableObject {
    
    // General
    private let userId: CKRecord.ID?
    @Published var isLoading: Bool = false
    @Published var saveButtonDisabled: Bool = true
    @Published var backButtonDisabled: Bool = false
    
    // Alert
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    // Nickname
    private var nicknamePassed = true
    private var actualNickname: String = ""
    @Published var nicknameError: NicknameError = .none
    @Published var nicknameIsChecking: Bool = false // Progress view
    @Published var availabilityIsPassed: Bool = false
    enum NicknameError: String {
        case nameIsUsed = "Nickname is already used"
        case length = "Enter 3 or more symbols"
        case unacceptableCharacters = "Nickname contains unacceptable characters"
        case none = "Enter from 3 to 20 symbols"
    }
    @Published var nicknameTextField: String = "" {
        didSet {
            if nicknameTextField.count > Limits.nicknameSymbolsLimit {
                nicknameTextField = nicknameTextField.truncated(limit: Limits.nicknameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    
    // FirstName
    private var firstNamePassed = true
    private var actualFirstName: String = ""
    @Published var firstNameError: FirstNameError = .none
    enum FirstNameError: String {
        case length = "Enter 2 or more letters"
        case unacceptableCharacters = "First name contains unacceptable characters"
        case none = "Enter your first name"
    }
    @Published var firstNameTextField: String = "" {
        didSet {
            if firstNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                firstNameTextField = firstNameTextField.truncated(limit: Limits.nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    
    // LastName
    private var lastNamePassed = true
    private var actualLastName: String = ""
    @Published var lastNameError: LastNameError = .none
    enum LastNameError: String {
        case length = "Enter 2 or more letters"
        case unacceptableCharacters = "Last name contains unacceptable characters"
        case none = "Enter your last name"
    }
    @Published var lastNameTextField: String = "" {
        didSet {
            if lastNameTextField.count > Limits.nameAndLastNameSymbolsLimit {
                lastNameTextField = lastNameTextField.truncated(limit: Limits.nameAndLastNameSymbolsLimit, position: .tail, leader: "")
            }
        }
    }
    
    // DateOfBirth
    private var actualDateOfBirth: Date = Date()
    @Published var dateOfBirthPicker: Date = Date()
    
    
    
    private var nicknameCheckTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(id: CKRecord.ID?) {
        userId = id
        fetchDataFromDatabase()
        addSubscribers()
    }
    
    private func addSubscribers() {
        let sharedNicknameTextField = $nicknameTextField.share()
        
        sharedNicknameTextField
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                Task {
                    await self.executeNicknameQuery()
                }
            }
            .store(in: &cancellables)
        
        sharedNicknameTextField
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.nicknameFieldChanged()
            }
            .store(in: &cancellables)
        
        let sharedFirstNameTextField = $firstNameTextField.share()
        
        sharedFirstNameTextField
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                Task {
                    await self.executeFirstNameQuery()
                }
            }
            .store(in: &cancellables)
        
        sharedFirstNameTextField
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.firstNameFieldChanged()
            }
            .store(in: &cancellables)
        
        let sharedLastNameTextField = $lastNameTextField.share()
        
        sharedLastNameTextField
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in
                Task {
                    await self.executeLastNameQuery()
                }
            }
            .store(in: &cancellables)
        
        sharedLastNameTextField
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.lastNameFieldChanged()
            }
            .store(in: &cancellables)
        
        $dateOfBirthPicker
            .sink { [weak self] _ in
                self?.checkForSaveButton()
            }
            .store(in: &cancellables)
    }
    
    private func nicknameFieldChanged() {
        nicknameCheckTask?.cancel()
        nicknameIsChecking = false
        availabilityIsPassed = false
        nicknamePassed = false
        nicknameError = .none
        checkForSaveButton()
    }
    
    private func firstNameFieldChanged() {
        firstNamePassed = false
        firstNameError = .none
        checkForSaveButton()
    }
    
    private func lastNameFieldChanged() {
        lastNamePassed = false
        lastNameError = .none
        checkForSaveButton()
    }
    
    private let cacheManager = CacheManager.instance
    
    func saveChanges() async {
        guard let id = userId else { return }
        await MainActor.run(body: {
            isLoading = true
            backButtonDisabled = true
        })
        if nicknameTextField != actualNickname {
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: id, field: .nicknameRecordField, newData: nicknameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualNickname = nicknameTextField
                    cacheManager.delete(from: cacheManager.textCache, "_nickname", for: id.recordName)
                    availabilityIsPassed = false
                    nicknameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving nickname", message: error.localizedDescription)
            }
        }
        if firstNameTextField != actualFirstName {
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: id, field: .firstNameRecordField, newData: firstNameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualFirstName = firstNameTextField
                    cacheManager.delete(from: cacheManager.textCache, "_firstName", for: id.recordName)
                    firstNameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving first name", message: error.localizedDescription)
            }
        }
        if lastNameTextField != actualLastName {
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: id, field: .lastNameRecordField, newData: lastNameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualLastName = lastNameTextField
                    cacheManager.delete(from: cacheManager.textCache, "_lastName", for: id.recordName)
                    lastNameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving last name", message: error.localizedDescription)
            }
        }
        if dateOfBirthPicker != actualDateOfBirth {
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: id, field: .dateOfBirthRecordField, newData: dateOfBirthPicker) {
            case .success(_):
                await MainActor.run(body: {
                    actualDateOfBirth = dateOfBirthPicker
                })
            case .failure(let error):
                showAlert(title: "Error while saving date of birth", message: error.localizedDescription)
            }
        }
        await MainActor.run(body: {
            withAnimation {
                checkForSaveButton()
                isLoading = false
                backButtonDisabled = false
            }
        })
    }
    
    private func checkForSaveButton() {
        DispatchQueue.main.async {
            self.saveButtonDisabled = !((self.nicknamePassed && self.firstNamePassed && self.lastNamePassed) && (self.nicknameTextField != self.actualNickname || self.firstNameTextField != self.actualFirstName || self.lastNameTextField != self.actualLastName || Calendar.current.dateComponents([.day, .year, .month], from: self.dateOfBirthPicker) != Calendar.current.dateComponents([.day, .year, .month], from: self.actualDateOfBirth)))
        }
    }
    
    func executeNicknameQuery() async {
        if !nicknameTextField.isEmpty {
            if nicknameTextField == actualNickname {
                nicknamePassed = true
            } else {
                if nicknameTextField.count < 3 {
                    await MainActor.run {
                        nicknameError = .length
                    }
                } else if nicknameTextField.containsUnacceptableSymbols() {
                    await MainActor.run {
                        nicknameError = .unacceptableCharacters
                    }
                } else {
                    nicknameCheckTask = Task {
                        await MainActor.run(body: {
                            nicknameIsChecking = true
                        })
                        switch await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .usersRecordType, withField: .nicknameRecordField, equalTo: nicknameTextField) {
                        case .success(let exist):
                            if !Task.isCancelled {
                                await MainActor.run {
                                    nicknameIsChecking = false
                                    if exist {
                                        availabilityIsPassed = false
                                        nicknameError = .nameIsUsed
                                        HapticManager.instance.notification(of: .error)
                                    } else {
                                        availabilityIsPassed = true
                                        nicknamePassed = true
                                        checkForSaveButton()
                                        HapticManager.instance.notification(of: .success)
                                    }
                                }
                            }
                        case .failure(let failure):
                            if !Task.isCancelled {
                                showAlert(title: "Server error", message: failure.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func executeFirstNameQuery() async {
        if !firstNameTextField.isEmpty {
            if firstNameTextField == actualFirstName {
                firstNamePassed = true
            } else {
                if firstNameTextField.count < 2 {
                    await MainActor.run {
                        firstNameError = .length
                    }
                } else if !firstNameTextField.containsOnlyLetters() {
                    await MainActor.run {
                        firstNameError = .unacceptableCharacters
                    }
                } else {
                    firstNamePassed = true
                    checkForSaveButton()
                }
            }
        }
    }
    
    func executeLastNameQuery() async {
        if !lastNameTextField.isEmpty {
            if lastNameTextField == actualLastName {
                lastNamePassed = true
            } else {
                if lastNameTextField.count < 2 {
                    await MainActor.run {
                        lastNameError = .length
                    }
                } else if !lastNameTextField.containsOnlyLetters() {
                    await MainActor.run {
                        lastNameError = .unacceptableCharacters
                    }
                } else {
                    lastNamePassed = true
                    checkForSaveButton()
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
    
    private func fetchDataFromDatabase() {
        guard let id = userId else { return }
        isLoading = true
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { [weak self] user, error in
            if let self = self {
                DispatchQueue.main.async {
                    if let user = user,
                       let nickname = user[.nicknameRecordField] as? String,
                       let firstName = user[.firstNameRecordField] as? String,
                       let lastName = user[.lastNameRecordField] as? String,
                       let dateOfBirth = user[.dateOfBirthRecordField] as? Date {
                        self.nicknameTextField = nickname
                        self.firstNameTextField = firstName
                        self.lastNameTextField = lastName
                        self.actualNickname = nickname
                        self.actualFirstName = firstName
                        self.actualLastName = lastName
                        self.actualDateOfBirth = dateOfBirth
                        self.dateOfBirthPicker = dateOfBirth
                    } else if let error = error {
                        self.showAlert(title: "Error fetching personal data", message: error.localizedDescription)
                    } else {
                        self.showAlert(title: "Cannot fetch personal data", message: "Contact support")
                    }
                    self.isLoading = false
                }
            }
        }
    }
}
