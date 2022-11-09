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
    
    // RecordID of current user
    private let userId: CKRecord.ID
    
    // Shows loading view if true
    @Published var isLoading: Bool = false
    
    // Disables save button
    @Published var saveButtonDisabled: Bool = true
    
    // Disables back button
    @Published var backButtonDisabled: Bool = false
    
    // Alert
    @Published var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    // Nickname
    // True if nickname checks were passed
    private var nicknamePassed = true
    
    // Current user's nickname
    private var actualNickname: String = ""
    
    // Error while checking nickname
    @Published var nicknameError: NicknameError = .none
    
    // Shows loading view if nickname is checking
    @Published var nicknameIsChecking: Bool = false
    
    // Shows if nickname availability test was passed
    @Published var availabilityIsPassed: Bool = false
    
    // Nickname text field
    @Published var nicknameTextField: String = "" 
    
    // FirstName
    // True if first name checks were passed
    private var firstNamePassed = true
    
    // Current user's first name
    private var actualFirstName: String = ""
    
    // Error while checking first name
    @Published var firstNameError: FirstNameError = .none
    
    // First name text field
    @Published var firstNameTextField: String = ""
    
    // LastName
    // True if last name checks were passed
    private var lastNamePassed = true
    
    // Current user's last name
    private var actualLastName: String = ""
    
    // Error while checking last name
    @Published var lastNameError: LastNameError = .none

    // Last name text field
    @Published var lastNameTextField: String = ""
    
    // DateOfBirth
    // Current user's date of birth
    private var actualDateOfBirth: Date = Date()
    
    // Date of birth picker
    @Published var dateOfBirthPicker: Date = Date()
    
    // Nickname checking task
    private var nicknameCheckTask: Task<Void, Never>?
    
    // Publishers storage
    private var cancellables = Set<AnyCancellable>()
    
    // Cache manager
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID) {
        userId = id
        fetchDataFromDatabase()
        addSubscribers()
    }
    
    /// Subscribes on publishers
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
    
    /// Perform actions if nickname text field was changed
    private func nicknameFieldChanged() {
        nicknameCheckTask?.cancel()
        nicknameIsChecking = false
        availabilityIsPassed = false
        nicknamePassed = false
        nicknameError = .none
        checkForSaveButton()
    }
    
    /// Perform actions if first name text field was changed
    private func firstNameFieldChanged() {
        firstNamePassed = false
        firstNameError = .none
        checkForSaveButton()
    }

    /// Perform actions if last name text field was changed
    private func lastNameFieldChanged() {
        lastNamePassed = false
        lastNameError = .none
        checkForSaveButton()
    }
        
    /// Saves all changes to database and cache
    func saveChanges() async {
        
        // Starts loading view
        await MainActor.run(body: {
            isLoading = true
            backButtonDisabled = true
        })
        
        // Checks if nickname was changed
        if nicknameTextField != actualNickname {
            
            // Updates record in database
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: userId, field: .nicknameRecordField, newData: nicknameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualNickname = nicknameTextField
                    if let savedUser = cacheManager.getFrom(cacheManager.userData, key: userId.recordName),
                       savedUser.user.nickname != actualNickname {
                        let actualUser = UserModel(id: savedUser.user.id, firstName: savedUser.user.firstName, lastName: savedUser.user.lastName, nickname: actualNickname, followers: savedUser.user.followers, following: savedUser.user.following)
                        cacheManager.addTo(cacheManager.userData, key: userId.recordName, value: UserModelHolder(actualUser))
                    }
                    availabilityIsPassed = false
                    nicknameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving nickname", message: error.localizedDescription)
            }
        }
        
        // Checks if first name was changed
        if firstNameTextField != actualFirstName {
            
            // Updates record in database
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: userId, field: .firstNameRecordField, newData: firstNameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualFirstName = firstNameTextField
                    if let savedUser = cacheManager.getFrom(cacheManager.userData, key: userId.recordName),
                       savedUser.user.firstName != actualFirstName {
                        let actualUser = UserModel(id: savedUser.user.id, firstName: actualFirstName, lastName: savedUser.user.lastName, nickname: savedUser.user.firstName, followers: savedUser.user.followers, following: savedUser.user.following)
                        cacheManager.addTo(cacheManager.userData, key: userId.recordName, value: UserModelHolder(actualUser))
                    }

                    firstNameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving first name", message: error.localizedDescription)
            }
        }
        
        // Checks if last name was changed
        if lastNameTextField != actualLastName {
            
            // Updates record in database
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: userId, field: .lastNameRecordField, newData: lastNameTextField) {
            case .success(_):
                await MainActor.run(body: {
                    actualLastName = lastNameTextField
                    if let savedUser = cacheManager.getFrom(cacheManager.userData, key: userId.recordName),
                       savedUser.user.lastName != actualLastName {
                        let actualUser = UserModel(id: savedUser.user.id, firstName: savedUser.user.firstName, lastName: actualLastName, nickname: savedUser.user.firstName, followers: savedUser.user.followers, following: savedUser.user.following)
                        cacheManager.addTo(cacheManager.userData, key: userId.recordName, value: UserModelHolder(actualUser))
                    }
                    lastNameError = .none
                })
            case .failure(let error):
                showAlert(title: "Error while saving last name", message: error.localizedDescription)
            }
        }
        
        // Checks if date of birth was changed
        if dateOfBirthPicker != actualDateOfBirth {
            
            // Updates record in database
            switch await CloudKitManager.instance.updateFieldForUserWith(recordId: userId, field: .dateOfBirthRecordField, newData: Calendar.current.startOfDay(for: dateOfBirthPicker)) {
            case .success(_):
                await MainActor.run(body: {
                    actualDateOfBirth = Calendar.current.startOfDay(for: dateOfBirthPicker)
                })
            case .failure(let error):
                showAlert(title: "Error while saving date of birth", message: error.localizedDescription)
            }
        }
        
        // Ends saving process
        await MainActor.run(body: {
            withAnimation {
                checkForSaveButton()
                isLoading = false
                backButtonDisabled = false
            }
        })
    }
    
    /// Checks if save button should be disabled
    private func checkForSaveButton() {
        DispatchQueue.main.async {
            self.saveButtonDisabled = !((self.nicknamePassed && self.firstNamePassed && self.lastNamePassed) && (self.nicknameTextField != self.actualNickname || self.firstNameTextField != self.actualFirstName || self.lastNameTextField != self.actualLastName || Calendar.current.dateComponents([.day, .year, .month], from: self.dateOfBirthPicker) != Calendar.current.dateComponents([.day, .year, .month], from: self.actualDateOfBirth)))
        }
    }
    
    /// Nickname checking process
    func executeNicknameQuery() async {
        if !nicknameTextField.isEmpty { // Checks if field is empty
            if nicknameTextField == actualNickname { // Checks if field equals actual nickname => no changes
                nicknamePassed = true
            } else {
                if nicknameTextField.count < 3 { // Checks if field length less than 3
                    await MainActor.run {
                        nicknameError = .length
                    }
                } else if nicknameTextField.containsUnacceptableSymbols() { // Checks if nickname contains unacceptable characters
                    await MainActor.run {
                        nicknameError = .unacceptableCharacters
                    }
                } else {
                    nicknameCheckTask = Task { // Finally checks if nickname is already used
                        await MainActor.run(body: {
                            nicknameIsChecking = true
                        })
                        switch await CloudKitManager.instance.doesRecordExistInPublicDatabase(inRecordType: .usersRecordType, withField: .nicknameRecordField, equalTo: nicknameTextField) {
                        case .success(let exist):
                            if !Task.isCancelled {
                                await MainActor.run {
                                    nicknameIsChecking = false
                                    if exist { // Shows that nickname is used
                                        availabilityIsPassed = false
                                        nicknameError = .nameIsUsed
                                        HapticManager.instance.notification(of: .error)
                                    } else { // Shows that nickname is free to use
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
    
    /// First name checking process
    func executeFirstNameQuery() async {
        if !firstNameTextField.isEmpty { // Checks if field is empty
            if firstNameTextField == actualFirstName { // Checks if field equals actual first name => no changes
                firstNamePassed = true
            } else {
                if firstNameTextField.count < 2 { // Checks if field length less than 2
                    await MainActor.run {
                        firstNameError = .length
                    }
                } else if !firstNameTextField.containsOnlyLetters() { // Checks if first name contains unacceptable characters
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
    
    /// Last name checking process
    func executeLastNameQuery() async {
        if !lastNameTextField.isEmpty { // Checks if field is empty
            if lastNameTextField == actualLastName { // Checks if field equals actual last name => no changes
                lastNamePassed = true
            } else {
                if lastNameTextField.count < 2 { // Checks if field length less than 2
                    await MainActor.run {
                        lastNameError = .length
                    }
                } else if !lastNameTextField.containsOnlyLetters() { // Checks if last name contains unacceptable characters
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
    
    /// Shows alert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    /// Fetches current user's data from database
    private func fetchDataFromDatabase() {
        isLoading = true
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: userId) { [weak self] user, error in
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
