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
        Button("Create 50 accounts") {
            for _ in 0...50 {
                Task {
                    await createAccount()
                }
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
