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
    
    @Published var image: UIImage? = nil
    @Published var isLoading: Bool = false
    @Published var firstName: String? = nil
    @Published var lastName: String? = nil
    @Published var nickname: String? = nil
    
    private var userRecordId: CKRecord.ID?
    private var logOutFunc: () async -> ()
    
    init(id: CKRecord.ID?, logOutFunc: @escaping () async -> ()) {
        userRecordId = id
        self.logOutFunc = logOutFunc
        Task {
            await sync()
        }
    }
    
    func logOut() async {
        await logOutFunc()
    }
    
    func sync() async {
        await getImage()
        await getFirstName()
        await getLastName()
        await getNickname()
    }
    
    func fullSync() async {
        await MainActor.run(body: {
            CacheManager.instance.cleanProfileTextCache()
            CacheManager.instance.cleanProfilePhotoCache()
        })
        await getImage()
        await getFirstName()
        await getLastName()
        await getNickname()
    }
    
    private func getNickname() async {
        guard let id = userRecordId else { return }
        if let savedNickname = CacheManager.instance.getTextFromProfileTextCache(key: "\(id.recordName)_nickname") as? String {
            await MainActor.run {
                withAnimation {
                    nickname = savedNickname
                }
            }
        } else {
            switch await UserInfoService.instance.fetchNicknameForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        self.nickname = returnedValue
                    }
                    if let nickname = returnedValue {
                        CacheManager.instance.addToProfileTextCache(key: "\(id.recordName)_nickname", value: NSString(string: nickname))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getFirstName() async {
        guard let id = userRecordId else { return }
        if let savedName = CacheManager.instance.getTextFromProfileTextCache(key: "\(id.recordName)_firstName") as? String {
            await MainActor.run {
                withAnimation {
                    firstName = savedName
                }
            }
        } else {
            switch await UserInfoService.instance.fetchFirstNameForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        self.firstName = returnedValue
                    }
                    if let firstName = returnedValue {
                        CacheManager.instance.addToProfileTextCache(key: "\(id.recordName)_firstName", value: NSString(string: firstName))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getLastName() async {
        guard let id = userRecordId else { return }
        if let savedName = CacheManager.instance.getTextFromProfileTextCache(key: "\(id.recordName)_lastName") as? String {
            await MainActor.run {
                withAnimation {
                    lastName = savedName
                }
            }
        } else {
            switch await UserInfoService.instance.fetchLastNameForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        self.lastName = returnedValue
                    }
                    if let lastName = returnedValue {
                        CacheManager.instance.addToProfileTextCache(key: "\(id.recordName)_lastName", value: NSString(string: lastName))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func uploadImage(_ image: UIImage?, for id: CKRecord.ID?) {
        guard let id = id else { return }
        DispatchQueue.main.async {
            withAnimation {
                self.image = nil
                self.isLoading = true
            }
        }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { record, error in
            if let record = record {
                if let image = image {
                   if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("avatar.jpg"),
                      let data = image.jpegData(compressionQuality: 0.2) {
                       do {
                           try data.write(to: url)
                           let asset = CKAsset(fileURL: url)
                           record[.avatarRecordField] = asset
                           Task {
                               let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                               await MainActor.run {
                                   withAnimation {
                                       self.image = UIImage(data: data)
                                       self.isLoading = false
                                   }
                               }
                               CacheManager.instance.addToProfilePhotoCache(key: "\(id.recordName)_avatar", value: image)
                           }
                       } catch {
                           print(error.localizedDescription)
                       }
                   }
                } else {
                    record[.avatarRecordField] = nil
                    Task {
                        let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                        await MainActor.run {
                            withAnimation {
                                self.isLoading = false
                            }
                        }
                        CacheManager.instance.cleanProfilePhotoCache()
                    }
                }
            } else {
                Task {
                    await self.getImage()
                }
            }
        }
    }
    
    private func getImage() async {
        guard let id = userRecordId else { return }
        if let savedImage = CacheManager.instance.getImageFromProfilePhotoCache(key: "\(id.recordName)_avatar") {
            await MainActor.run(body: {
                withAnimation {
                    image = savedImage
                }
            })
        } else {
            await MainActor.run {
                withAnimation {
                    image = nil
                    isLoading = true
                }
            }
            switch await AvatarImageService.instance.fetchAvatarForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    withAnimation {
                        isLoading = false
                        self.image = returnedValue
                    }
                    if let image = returnedValue {
                        CacheManager.instance.addToProfilePhotoCache(key: "\(id.recordName)_avatar", value: image)
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }}
