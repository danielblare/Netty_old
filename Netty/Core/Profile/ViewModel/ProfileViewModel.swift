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
    
    let userRecordId: CKRecord.ID?
    private var logOutFunc: () async -> ()
    private let cacheManager = CacheManager.instance
    
    init(id: CKRecord.ID?, logOutFunc: @escaping () async -> ()) {
        userRecordId = id
        self.logOutFunc = logOutFunc
        Task {
            await getData()
        }
    }
    
    func logOut() async {
        await logOutFunc()
    }
    
    func getData() async {
        await getImage()
        await getFirstName()
        await getLastName()
        await getNickname()
    }
    
    func sync() async {
        guard let id = userRecordId else { return }
        cacheManager.delete(from: cacheManager.textCache, "_firstName", for: id.recordName)
        cacheManager.delete(from: cacheManager.textCache, "_nickname", for: id.recordName)
        cacheManager.delete(from: cacheManager.textCache, "_lastName", for: id.recordName)
        cacheManager.delete(from: cacheManager.photoCache, "_avatar", for: id.recordName)
        await getData()
    }
    
    private func getNickname() async {
        guard let id = userRecordId else { return }
        if let savedNickname = cacheManager.getFrom(cacheManager.textCache, key: "\(id.recordName)_nickname") as? String {
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
                        cacheManager.addTo(cacheManager.textCache, key: "\(id.recordName)_nickname", value: NSString(string: nickname))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getFirstName() async {
        guard let id = userRecordId else { return }
        if let savedName = cacheManager.getFrom(cacheManager.textCache, key: "\(id.recordName)_firstName") as? String {
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
                        cacheManager.addTo(cacheManager.textCache, key: "\(id.recordName)_firstName", value: NSString(string: firstName))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getLastName() async {
        guard let id = userRecordId else { return }
        if let savedName = cacheManager.getFrom(cacheManager.textCache, key: "\(id.recordName)_lastName") as? String {
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
                        cacheManager.addTo(cacheManager.textCache, key: "\(id.recordName)_lastName", value: NSString(string: lastName))
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
                               self.cacheManager.addTo(self.cacheManager.photoCache, key: "\(id.recordName)_avatar", value: image)
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
                        self.cacheManager.delete(from: self.cacheManager.photoCache, "_avatar", for: record.recordID.recordName)
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
        if let savedImage = cacheManager.getFrom(cacheManager.photoCache, key: "\(id.recordName)_avatar") {
            await MainActor.run(body: {
                withAnimation {
                    image = savedImage
                }
            })
        } else {
            await MainActor.run {
                withAnimation {
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
                        cacheManager.addTo(cacheManager.photoCache, key: "\(id.recordName)_avatar", value: image)
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }}
