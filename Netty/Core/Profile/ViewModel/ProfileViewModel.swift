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
    @Published var fullName: String? = nil
    @Published var nickname: String? = nil
    
    private var userRecordId: CKRecord.ID?
    
    init(id: CKRecord.ID?) {
        userRecordId = id
        Task {
            await sync()
        }
    }
    
    func sync() async {
        await getImage()
        await getFullName()
        await getNickname()
    }
    
    func fullSync() async {
        await MainActor.run(body: {
            CacheManager.instance.cleanProfileTextCache()
            CacheManager.instance.cleanProfilePhotoCache()
        })
        await getImage()
        await getFullName()
        await getNickname()
    }
    
    private func getNickname() async {
        guard let id = userRecordId else { return }
        if let savedNickname = CacheManager.instance.getTextFromProfileTextCache(key: "\(id.recordName)_nickname") as? String {
            await MainActor.run {
                nickname = savedNickname
            }
        } else {
            switch await UserInfoService.instance.fetchNicknameForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    self.nickname = returnedValue
                    if let nickname = returnedValue {
                        CacheManager.instance.addToProfileTextCache(key: "\(id.recordName)_nickname", value: NSString(string: nickname))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getFullName() async {
        guard let id = userRecordId else { return }
        if let savedName = CacheManager.instance.getTextFromProfileTextCache(key: "\(id.recordName)_fullName") as? String {
            await MainActor.run {
                fullName = savedName
            }
        } else {
            switch await UserInfoService.instance.fetchFullNameForUser(with: id) {
            case .success(let returnedValue):
                await MainActor.run(body: {
                    self.fullName = returnedValue
                    if let fullName = returnedValue {
                        CacheManager.instance.addToProfileTextCache(key: "\(id.recordName)_fullName", value: NSString(string: fullName))
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func uploadImage(_ image: UIImage, for id: CKRecord.ID?) {
        guard let id = id else { return }
        DispatchQueue.main.async {
            self.image = nil
            self.isLoading = true
        }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) { record, error in
            if let record = record,
               let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathExtension("avatar.jpg"),
               let data = image.jpegData(compressionQuality: 0.2) {
                print("\(data.count)")
                do {
                    try data.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    record[.avatarRecordField] = asset
                    Task {
                        let _ = await CloudKitManager.instance.saveRecordToPublicDatabase(record)
                        await MainActor.run {
                            self.image = UIImage(data: data)
                            self.isLoading = false
                        }
                        CacheManager.instance.addToProfilePhotoCache(key: "\(id.recordName)_avatar", value: image)
                    }
                } catch {
                    print(error.localizedDescription)
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
                    isLoading = false
                    self.image = returnedValue
                    if let image = returnedValue {
                        CacheManager.instance.addToProfilePhotoCache(key: "\(id.recordName)_avatar", value: image)
                    }
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }}
