//
//  CloudKitManager.swift
//  Netty
//
//  Created by Danny on 21/07/2022.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

actor CloudKitManager {
    
    private init() {}
    
    static let instance = CloudKitManager()
        
    /// Checks if given user exists in `inRecordType` of public database `withField` which equals to `equalTo`.
    ///
    /// - Parameters:
    ///     - inRecordType: Record type where search will be completed.
    ///     - withField: User's field.
    ///     - equalTo: Value of stated field.
    ///
    /// - Returns: Result of bool with possible error.
    func doesRecordExistInPublicDatabase(inRecordType: String, withField: String, equalTo: String) async -> Result<Bool, Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "\(withField) == %@", equalTo.lowercased())
            let query = CKQuery(recordType: inRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    continuation.resume(returning: .success(!success.matchResults.isEmpty))
                case .failure(let failure):
                    continuation.resume(returning: .failure(failure))
                }
            }
        }
    }
    
    func doesChatExistWith(participants: (CKRecord.Reference, CKRecord.Reference)) async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            let predicate1 = NSPredicate(format: "\(String.participantsRecordField) CONTAINS %@", participants.0)
            let predicate2 = NSPredicate(format: "\(String.participantsRecordField) CONTAINS %@", participants.1)
            let predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2])
            let query = CKQuery(recordType: .chatsRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    continuation.resume(returning: .success(success.matchResults.first?.0))
                case .failure(let failure):
                    continuation.resume(returning: .failure(failure))
                }
            }
        }
    }

    /// Saves `record` to public database.
    ///
    /// - Parameters:
    ///     - record: Record that will be saved.
    ///
    /// - Returns: Result of returned record with possible error.
    func saveRecordToPublicDatabase(_ record: CKRecord) async -> Result<CKRecord, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                }
                if let returnedRecord = returnedRecord {
                    continuation.resume(returning: .success(returnedRecord))
                }
            }
        }
    }
    
    /// Returns id of user `withField` which equals to `equalTo` stored in `inRecordType` of public database.
    ///
    /// - Parameters:
    ///     - withField: User's field.
    ///     - inRecordType: Record type where search will be completed.
    ///     - equalTo: Value of stated field.
    ///
    /// - Returns: Result of possible returned record with possible error.
    func recordIdOfUser(withField: String, inRecordType: String, equalTo: String) async -> Result<CKRecord.ID?, Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(format: "\(withField) == %@", equalTo.lowercased())
            let query = CKQuery(recordType: inRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil) { completion in
                switch completion {
                case .success(let success):
                    continuation.resume(returning: .success(success.matchResults.first?.0))
                case .failure(let failure):
                    continuation.resume(returning: .failure(failure))
                }
            }
        }
    }
    
    /// Updates `field` with `newData` for user with `recordId`
    ///
    /// - Parameters:
    ///     - recordId: User's recordId
    ///     - field: User's field.
    ///     - newData: New data.
    ///
    /// - Returns: Result of returned record with possible error.
    func updateFieldForUserWith<T:Any>(recordId: CKRecord.ID, field: String, newData: T) async -> Result<CKRecord, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordId) { returnedRecord, error in
                if let record = returnedRecord {
                    record[field] = newData as? (any __CKRecordObjCValue)
                    CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, error in
                        if let record = returnedRecord {
                            continuation.resume(returning: .success(record))
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
}

