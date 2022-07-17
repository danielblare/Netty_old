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
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func containsUnacceptableSymbols() -> Bool {
        let characterset = CharacterSet(charactersIn: String.specialSymbols + String.capitalLetters + String.lowercasedLetters + String.numbers)
        if self.rangeOfCharacter(from: characterset.inverted) != nil {
            return true
        }
        return false
    }
    
    func containsSpecialSymbols() -> Bool {
        let characterset = CharacterSet(charactersIn: String.specialSymbols)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    func containsNumbers() -> Bool {
        let characterset = CharacterSet(charactersIn: String.numbers)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    func containsCapitalLetters() -> Bool {
        let characterset = CharacterSet(charactersIn: String.capitalLetters)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
    func containsLowercasedLetters() -> Bool {
        let characterset = CharacterSet(charactersIn: String.lowercasedLetters)
        if self.rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    
}
