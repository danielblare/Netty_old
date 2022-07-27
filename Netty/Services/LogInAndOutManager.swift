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
    
    func logIn(username: String, password: String) async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "nickname == %@", username)
            let query = CKQuery(recordType: "AllUsers", predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    if success.matchResults.count > 0 {
                        let id: Result<CKRecord.ID?, Error> = success.matchResults.first!.1.map { result in
                            if result.value(forKey: "password") as? String == password {
                                return result.recordID
                            } else {
                                return nil
                            }
                        }
                        switch id {
                        case .success(let recordId):
                            continuation.resume(returning: .success(recordId))
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                        }
                    } else {
                        let predicate = NSPredicate(format: "email == %@", username)
                        let query = CKQuery(recordType: "AllUsers", predicate: predicate)
                        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                            switch completion {
                            case .success(let success):
                                if success.matchResults.count > 0 {
                                    let id: Result<CKRecord.ID?, Error> = success.matchResults.first!.1.map { result in
                                        if result.value(forKey: "password") as? String == password {
                                            return result.recordID
                                        } else {
                                            return nil
                                        }
                                    }
                                    switch id {
                                    case .success(let recordId):
                                        continuation.resume(returning: .success(recordId))
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
    
    func addLoggedInDevice(for recordID: CKRecord.ID) {
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { returnedRecord, error in
            if error == nil,
            let record = returnedRecord {
                CKContainer.default().fetchUserRecordID { returnedRecord, error in
                    if error == nil,
                       let id = returnedRecord?.recordName {
                        record["loggedInDevice"] = "\(id)"
                        CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
                    }
                }
            }
        }
    }
    
    func removeLoggedInDevice(for recordID: CKRecord.ID) {
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { returnedRecord, error in
            if error == nil,
            let record = returnedRecord {
            record["loggedInDevice"] = ""
            CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
            }
        }
    }
    
    func logOut() async -> Result<Void, Error> {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return await withCheckedContinuation { continuation in
            continuation.resume(returning: .success(()))
        }
    }
}

