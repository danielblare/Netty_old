//
//  LogInAndOutManager.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import Foundation
import SwiftUI

actor LogInAndOutManager {
    
    private init() {}
    static let instance = LogInAndOutManager()
    
    func logIn(username: String, password: String) async -> Result<Void, Error> {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if username == "stuffeddanny" && password == "1232123" {
            return .success(())
        } else {
            return .failure(URLError(.badServerResponse))
        }
    }
    
    func logOut() async -> Result<Void, Error> {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return .success(())
    }
}

