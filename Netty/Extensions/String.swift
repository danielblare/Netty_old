//
//  String.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation

extension String {
    
    func containsOnlyLetters() -> Bool {
       for chr in self {
          if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
             return false
          }
       }
       return true
    }
}
