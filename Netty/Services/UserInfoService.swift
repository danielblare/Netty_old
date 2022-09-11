//
//  UserInfoService.swift
//  Netty
//
//  Created by Danny on 9/11/22.
//

import Foundation
import SwiftUI
import CloudKit

actor UserInfoService {
    
    
    static let instance = UserInfoService()
    
    private init() {}
    
    func fetchFullNameForUser(with id: CKRecord.ID) async -> Result<String?, Error> {
        await withCheckedContinuation { continuation in
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { returnedRecord, error in
                if let returnedRecord = returnedRecord {
                    if let firstName = returnedRecord[.firstNameRecordField] as? String,
                       let lastName = returnedRecord[.lastNameRecordField] as? String {
                        continuation.resume(returning: .success("\(firstName) \(lastName)"))
                    } else {
                        continuation.resume(returning: .success(nil))
                    }
                } else if let error = error {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
