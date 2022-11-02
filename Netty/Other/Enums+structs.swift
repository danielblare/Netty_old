//
//  Enums+structs.swift
//  Netty
//
//  Created by Danny on 10/31/22.
//

import Foundation


enum EmailButtonText: String {
    case send = "Send code"
    case again = "Send again"
    case verified = ""
}


enum PasswordWarningMessage: String {
    case short = "Enter at least 8 symbols"
    case unacceptableSymbols = "Password contains unacceptable symbols"
    case numbersAndLetters = "Password should contain letters and numbers"
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    case veryStrong = "Very strong"
}

enum LogInError: Error {
    case noUserFound
}

extension LogInError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUserFound:
            return NSLocalizedString("User with this nickname or e-mail does not exist", comment: "Used wasn't found")
        }
    }
}

enum EmailSendingError: Error {
    case serialization
    case url
}

extension EmailSendingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serialization:
            return NSLocalizedString("Error while serialization data", comment: "Error while sending e-mail")
        case .url:
            return NSLocalizedString("Error while getting URL", comment: "URL getting error")
        }
    }
}

struct Limits {
    static let nameAndLastNameSymbolsLimit: Int = 35
    static let emailSymbolsLimit: Int = 64
    static let nicknameSymbolsLimit: Int = 20
    static let passwordSymbolsLimit: Int = 23
    static let usersInRecentsLimit: Int = 5
}

enum NicknameError: String {
    case nameIsUsed = "Nickname is already used"
    case length = "Enter 3 or more symbols"
    case unacceptableCharacters = "Nickname contains unacceptable characters"
    case none = "Enter from 3 to 20 symbols"
}

enum FirstNameError: String {
    case length = "Enter 2 or more letters"
    case unacceptableCharacters = "First name contains unacceptable characters"
    case none = "Enter your first name"
}

enum LastNameError: String {
    case length = "Enter 2 or more letters"
    case unacceptableCharacters = "Last name contains unacceptable characters"
    case none = "Enter your last name"
}

enum WarningMessage: String {
    case usernameIsShort = "Username less than 3 symbols"
    case passwordIsShort = "Password less than 8 symbols"
    case none = ""
}
