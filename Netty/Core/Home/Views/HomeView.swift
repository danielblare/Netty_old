//
//  HomeView.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI
import CloudKit

struct HomeView: View {
        
    // View Model
    @StateObject private var vm = HomeViewModel()
        
    var body: some View {
        VStack(spacing: 50) {
            Button("Create 50 accounts") {
                for _ in 0...50 {
                    Task {
                        await createAccount()
                    }
                }
            }
            
            Button("Add bytes") {
//                CKContainer.default().publicCloudDatabase.fetch(withRecordID: .init(recordName: "A3B9378A-5265-B0C8-238D-DE97CAAF9B6C")) { returnedRecord, error in
//                    if let record = returnedRecord {
//                        let messages = record[.messagesRecordField] as? [Data]
//                        print(messages)
//                    }
//                }
//                CKContainer.default().publicCloudDatabase.fetch(withRecordID: .init(recordName: "A3B9378A-5265-B0C8-238D-DE97CAAF9B6C")) { returnedRecord, error in
//                    if let error = error {
//                        print(error.localizedDescription)
//                    } else if let chatRecord = returnedRecord {
//                        print(chatRecord)
//                        print(chatRecord["messages"])
//                        let a = try! JSONEncoder().encode(ChatMessageModel(id: "30E1675A-A59C-4FB4-8A2A-5E99D197E736", message: "hello", date: .now))
//                        let b = try! JSONEncoder().encode(ChatMessageModel(id: "A6244FDA-A0DA-47CB-8E12-8F2603271899", message: "Hello", date: .now))
//                        chatRecord["messages"] = [a, b]
//                        CKContainer.default().publicCloudDatabase.save(chatRecord) { returnedRecord, error in
//                            if let returnedRecord = returnedRecord {
//                                print(returnedRecord)
//                            }
//                        }
//                    } else {
//                        print("Error")
//                    }
//                }
            }
        }
    }
    
    
    func createAccount() async {
        let firstName = randomString(length: 10)
        let lastName = randomString(length: 10)
        let dateOfBirth = Calendar.current.startOfDay(for: .now)
        let nickname = randomString(length: 10)
        let email = randomString(length: 10)
        let password = randomString(length: 10)
        
        let newUser = CKRecord(recordType: .usersRecordType)
        newUser[.firstNameRecordField] = firstName
        newUser[.lastNameRecordField] = lastName
        newUser[.dateOfBirthRecordField] = dateOfBirth
        newUser[.emailRecordField] = email
        newUser[.nicknameRecordField] = nickname
        newUser[.passwordRecordField] = password
        newUser[.avatarRecordField] = nil
        newUser[.loggedInDeviceRecordField] = ""
        
        switch await CloudKitManager.instance.saveRecordToPublicDatabase(newUser) {
        case .success(let record):
            print("Successfully created \(record.recordID)")
        case .failure(let error):
            print("error \(error.localizedDescription)")
        }
        
    }
    
    func randomString(length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
}






struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
        HomeView()
            .preferredColorScheme(.light)
    }
}
