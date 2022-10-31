//
//  LogInAndOutManager.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import Foundation
import SwiftUI
import CloudKit

actor LogInAndOutManager {
    
    private init() {}
    static let instance = LogInAndOutManager()
    
    func logIn(username: String, password: String) async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "\(String.nicknameRecordField) == %@", username)
            let query = CKQuery(recordType: .usersRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    if success.matchResults.count > 0 {
                        let id: Result<CKRecord.ID?, Error> = success.matchResults.first!.1.map { result in
                            if result.value(forKey: .passwordRecordField) as? String == password {
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
                        let predicate = NSPredicate(format: "\(String.emailRecordField) == %@", username)
                        let query = CKQuery(recordType: .usersRecordType, predicate: predicate)
                        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                            switch completion {
                            case .success(let success):
                                if success.matchResults.count > 0 {
                                    let id: Result<CKRecord.ID?, Error> = success.matchResults.first!.1.map { result in
                                        if result.value(forKey: .passwordRecordField) as? String == password {
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
            if let record = returnedRecord {
                CKContainer.default().fetchUserRecordID { returnedRecord, error in
                    if let id = returnedRecord?.recordName {
                        record[.loggedInDeviceRecordField] = "\(id)"
                        CKContainer.default().publicCloudDatabase.save(record) { _, _ in }
                    }
                }
            }
        }
    }
    
    private func removeLoggedInDevice(for recordID: CKRecord.ID) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { returnedRecord, error in
                if let record = returnedRecord {
                    record[.loggedInDeviceRecordField] = ""
                    CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                        if let _  = returnedRecord {
                            continuation.resume(returning: .success(()))
                        } else if let error = error {
                            continuation.resume(returning: .failure(error))
                        }
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func checkLoggedInDevise() async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().fetchUserRecordID { returnedRecord, error in
                if let record = returnedRecord {
                    let predicate = NSPredicate(format: "\(String.loggedInDeviceRecordField) == %@", "\(record.recordName)")
                    let query = CKQuery(recordType: .usersRecordType, predicate: predicate)
                    CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                        switch completion {
                        case .success(let success):
                            if success.matchResults.isEmpty {
                                continuation.resume(returning: .success(nil))
                            } else {
                                continuation.resume(returning: .success(success.matchResults.first.map({ recordId, _ in
                                    recordId
                                })))
                            }
                        case .failure(let failure):
                            continuation.resume(returning: .failure(failure))
                        }
                    }
                    
                } else if let error = error {
                    print("AMIGO \(error.localizedDescription)")
                }
            }
        }
    }
    
    func logOut(for id: CKRecord.ID) async -> Result<Void, Error> {
         await removeLoggedInDevice(for: id)
    }
}

