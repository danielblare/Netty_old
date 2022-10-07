//
//  String.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation

extension String {
    
    
    static let specialSymbols = "$&+,:;=?@#|'<>`~.-^*()%![]_{}"
    static let capitalLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static let lowercasedLetters = "abcdefghijklmnopqrstuvwxyz"
    static let numbers = "0123456789"
    static let usersRecordType = "AllUsers"
    static let chatsRecordType = "AllChats"
    static let emailRecordField = "email"
    static let avatarRecordField = "avatar"
    static let nicknameRecordField = "nickname"
    static let loggedInDeviceRecordField = "loggedInDevice"
    static let passwordRecordField = "password"
    static let firstNameRecordField = "firstName"
    static let lastNameRecordField = "lastName"
    static let dateOfBirthRecordField = "dateOfBirth"
    static let chatsRecordField = "chats"
    static let participantsRecordField = "participants"
    static let recentsUserInSearchRecordField = "recentUsersInSearch"
    

    
    /// Checks whether string contains only latin letters
    func containsOnlyLetters() -> Bool {
       for chr in self {
          if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
             return false
          }
       }
       return true
    }
    
    enum TruncationPosition {
            case head
            case middle
            case tail
        }

    /// Returns truncated string
    func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
        guard self.count > limit else { return self }

        switch position {
        case .head:
            return leader + self.suffix(limit)
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))

            let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
            
            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(limit) + leader
        }
    }
    
    /// Checks whether string is valid email adress
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Checks whether string contains unacceptable symbols such as non latin letters or spaces
    func containsUnacceptableSymbols() -> Bool {
        let characterset = CharacterSet(charactersIn: String.specialSymbols + String.capitalLetters + String.lowercasedLetters + String.numbers)
        if self.rangeOfCharacter(from: characterset.inverted) != nil {
            return true
        }
        return false
    }
    
    /// Checks whether string contains something except numbers
    func containsSomethingExceptNumbers() -> Bool {
        let characterset = CharacterSet(charactersIn: String.numbers)
        if self.rangeOfCharacter(from: characterset.inverted) != nil {
            return true
        }
        return false
    }
    
    /// Checks whether string contains special symbols
    func containsSpecialSymbols() -> Bool {
        let characterset = CharacterSet(charactersIn: String.specialSymbols)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    /// Checks whether string contains numbers
    func containsNumbers() -> Bool {
        let characterset = CharacterSet(charactersIn: String.numbers)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    /// Checks whether string contains capital letters
    func containsCapitalLetters() -> Bool {
        let characterset = CharacterSet(charactersIn: String.capitalLetters)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    /// Checks whether string contains lowercased letters
    func containsLowercasedLetters() -> Bool {
        let characterset = CharacterSet(charactersIn: String.lowercasedLetters)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    static func generateOneTimeCode() -> String {
        var res = ""
        
        for _ in 1...6 {
            res.append("\(Int.random(in: 0...9))")
        }

        return res
    }
    
}
