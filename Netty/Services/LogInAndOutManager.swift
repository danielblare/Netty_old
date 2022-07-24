//
//  LogInAndOutManager.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import Foundation
import SwiftUI
import CloudKit

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

actor LogInAndOutManager {
    
    private init() {}
    static let instance = LogInAndOutManager()
    
    func logIn(username: String, password: String) async -> Result<Bool, Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "nickname == %@", username)
            let query = CKQuery(recordType: "PrivateUsers", predicate: predicate)
            CKContainer.default().privateCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    if success.matchResults.count > 0 {
                        let result = success.matchResults.first!.1.map { result in
                            result.value(forKey: "password") as? String == password
                        }
                        switch result {
                        case .success(let correct):
                            if correct {
                                continuation.resume(returning: .success(true))
                            } else {
                                continuation.resume(returning: .success(false))
                            }
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                        }
                    } else {
                        
                        
                        let predicate = NSPredicate(format: "email == %@", username)
                        let query = CKQuery(recordType: "PrivateUsers", predicate: predicate)
                        CKContainer.default().privateCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                            switch completion {
                            case .success(let success):
                                if success.matchResults.count > 0 {
                                    let result = success.matchResults.first!.1.map { result in
                                        result.value(forKey: "password") as? String == password
                                    }
                                    switch result {
                                    case .success(let correct):
                                        if correct {
                                            continuation.resume(returning: .success(true))
                                        } else {
                                            continuation.resume(returning: .success(false))
                                        }
                                    case .failure(let error):
                                        continuation.resume(returning: .failure(error))
                                    }
                                } else {
                                    continuation.resume(returning: .failure(LogInError.noUserFound))
                                }
                            case .failure(let error):
                                continuation.resume(returning: .failure(error))
                            }
                        }
                    }
                    
                    
                    
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func logOut() async -> Result<Void, Error> {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return .success(())
    }
}

