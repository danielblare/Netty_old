//
//  FindUserModelService.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import Foundation
import CloudKit


actor FindUserModelService {
    
    static let instance = FindUserModelService()
    
    private init() {}
    
    func downloadData() async -> Result<[FindUserModel], Error> {
        await withCheckedContinuation { continuation in
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: .usersRecordType, predicate: predicate)
            CKContainer.default().publicCloudDatabase.fetch(withQuery: query) { completion in
                switch completion {
                case .success(let recordsArray):
                    var result: [FindUserModel] = []
                    for record in recordsArray.matchResults {
                        switch record.1 {
                        case .success(let userRecord):
                            if let firstName = userRecord[.firstNameRecordField] as? String,
                               let lastName = userRecord[.lastNameRecordField] as? String,
                               let nickname = userRecord[.nicknameRecordField] as? String {
                                result.append(FindUserModel(id: userRecord.recordID, firstName: firstName, lastName: lastName, nickname: nickname))
                            }
                            
                        case .failure(_):
                            break
                        }
                    }
                    continuation.resume(returning: .success(result))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
