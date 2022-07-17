//
//  Character.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import Foundation

extension Character {
    
    /// Checks whether character exists in string which is set of charactes
    func existsInSet(of string: String) -> Bool {
        let characterset = CharacterSet(charactersIn: string)
        if "\(self)".rangeOfCharacter(from: characterset) != nil {
            return true
        }
        return false
    }
    

}
