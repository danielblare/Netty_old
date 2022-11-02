//
//  ProfileViewModel.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    
    // Alert data
    var alertTitle: String = ""
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    // Profile avatar image
    @Published var image: UIImage? = nil
    
    // View is loading if true
    @Published var isLoading: Bool = false
    
    // User's first name
    @Published var firstName: String? = nil
    
    // User's last name
    @Published var lastName: String? = nil
    
    // User's nickname
    @Published var nickname: String? = nil
    
    // User's record ID
    let userId: CKRecord.ID
    
    // Log out function passed from LogInAndOutViewModel
    private var logOutFunc: () async -> ()
    
    // Cache manager to save some user's data in cache
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID, logOutFunc: @escaping () async -> ()) {
        userId = id
        self.logOutFunc = logOutFunc
        Task {
            await getData()
        }
    }
    
    /// Log out function for current user
    func logOut() async {
        await logOutFunc()
    }
    
    /// Gets all user's data
    func getData() async {
        await getImage()
        await getFirstName()
        await getLastName()
        await getNickname()
    }
    
    /// Deletes user's data from cache and downloads new fresh data from database
    func sync() async {
        cacheManager.delete(from: cacheManager.textCache, "_firstName", for: userId.recordName)
        cacheManager.delete(from: cacheManager.textCache, "_nickname", for: userId.recordName)
        cacheManager.delete(from: cacheManager.textCache, "_lastName", for: userId.recordName)
        cacheManager.delete(from: cacheManager.photoCache, "_avatar", for: userId.recordName)
        await getData()
    }
    
    /// Gets user's nickname
    private func getNickname() async {
        // Checks if user's nickname already saved in cache
        if let savedNickname = cacheManager.getFrom(cacheManager.textCache, key: "\(userId.recordName)_nickname") as? String {
            await MainActor.run {
                withAnimation {
                    nickname = savedNickname
                }
            }
        } else {
            
            // Downloads user's nickname from database
            switch await UserInfoService.instance.fetchNicknameForUser(with: userId) {
            case .success(let returnedValue):
                await MainActor.run {
                    withAnimation {
                        self.nickname = returnedValue
                    }
                    if let nickname = returnedValue { // Saves fetched data in the cache
                        cacheManager.addTo(cacheManager.textCache, key: "\(userId.recordName)_nickname", value: NSString(string: nickname))
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching nickname", message: error.localizedDescription)
            }
        }
    }
    
    /// Gets user's first name
    private func getFirstName() async {
        
        // Checks if user's first name already saved in cache
        if let savedName = cacheManager.getFrom(cacheManager.textCache, key: "\(userId.recordName)_firstName") as? String {
            await MainActor.run {
                withAnimation {
                    firstName = savedName
                }
            }
        } else {
            
            // Downloads user's first name from database
            switch await UserInfoService.instance.fetchFirstNameForUser(with: userId) {
            case .success(let returnedValue):
                await MainActor.run {
                    withAnimation {
                        self.firstName = returnedValue
                    }
                    if let firstName = returnedValue { // Saves fetched data in the cache
                        cacheManager.addTo(cacheManager.textCache, key: "\(userId.recordName)_firstName", value: NSString(string: firstName))
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching first name", message: error.localizedDescription)
            }
        }
    }
    
    /// Gets user's last name
    private func getLastName() async {
        
        // Checks if user's last name already saved in cache
        if let savedName = cacheManager.getFrom(cacheManager.textCache, key: "\(userId.recordName)_lastName") as? String {
            await MainActor.run {
                withAnimation {
                    lastName = savedName
                }
            }
        } else {
            
            // Downloads user's last name from database
            switch await UserInfoService.instance.fetchLastNameForUser(with: userId) {
            case .success(let returnedValue):
                await MainActor.run {
                    withAnimation {
                        self.lastName = returnedValue
                    }
                    if let lastName = returnedValue { // Saves fetched data in the cache
                        cacheManager.addTo(cacheManager.textCache, key: "\(userId.recordName)_lastName", value: NSString(string: lastName))
                    }
                }
            case .failure(let error):
                showAlert(title: "Error while fetching last name", message: error.localizedDescription)
            }
        }
    }
    
    /// Gets current user's avatar
    private func getImage() async {
        
        // Checks if user's avatar already saved in cache
        if let savedImage = cacheManager.getFrom(cacheManager.photoCache, key: "\(userId.recordName)_avatar") {
            await MainActor.run {
                withAnimation {
                    image = savedImage
                }
            }
        } else {

            // Starts loading
            await MainActor.run {
                withAnimation {
                    isLoading = true
                }
            }
            
            // Downloads user's avatar from database
            switch await AvatarImageService.instance.fetchAvatarForUser(with: userId) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        isLoading = false
                        self.image = returnedValue
                    }
                    if let image = returnedValue { // Saves fetched data in the cache
                        cacheManager.addTo(cacheManager.photoCache, key: "\(userId.recordName)_avatar", value: image)
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    /// Uploads new image as user's avatar to database
    func uploadImage(_ image: UIImage?, for id: CKRecord.ID) {
        
        // Removes old image from the screen, starts loading
        DispatchQueue.main.async {
            withAnimation {
                self.image = nil
                self.isLoading = true
            }
        }
        
        // Fetches the user from database
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { record, error in
            if let record = record { // Checks if record exists
                if let image = image { // Checks if image isn't nil
                   if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("avatar.jpg"),
                      let data = image.jpegData(compressionQuality: 0.2) { // Compresses image
                       do {
                           try data.write(to: url) // Writes compressed data
                           let asset = CKAsset(fileURL: url)
                           record[.avatarRecordField] = asset // Sets new image to avatar record field
                           
                           // Saves updated with new image record
                           Task {
                               let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                               await MainActor.run {
                                   withAnimation { // Stops loading and sets new image as avatar on the screen
                                       self.image = UIImage(data: data)
                                       self.isLoading = false
                                   }
                               }
                               // Saves new image in the cache
                               self.cacheManager.addTo(self.cacheManager.photoCache, key: "\(id.recordName)_avatar", value: image)
                           }
                       } catch {
                           self.showAlert(title: "Error while writing image", message: error.localizedDescription)
                       }
                   }
                } else { // Sets user's image to nil because image is broken
                    record[.avatarRecordField] = nil
                    Task { // Saves updated user to database
                        let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                        await MainActor.run {
                            withAnimation {
                                self.isLoading = false
                            }
                        }
                        
                        // Deletes current avatar from the cache
                        self.cacheManager.delete(from: self.cacheManager.photoCache, "_avatar", for: record.recordID.recordName)
                    }
                }
            } else { // Fetching current avatar because cannot fetch user's record
                if let error = error {
                    self.showAlert(title: "Error while fetching user's record", message: error.localizedDescription)
                }
                
                Task {
                    await self.getImage()
                }
            }
        }
    }
    
    /// Shows alert on the screen
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        DispatchQueue.main.async {
            self.showAlert = true
        }
    }
}
