//
//  PhotoModelFileManager.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import SwiftUI

class PhotoModelFileManager {
    
    static let instance = PhotoModelFileManager()
    private let folderName = "avatars"
    
    private init() {
        createFolderIfNeeded()
    }
    
    private func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path()) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func getFolderPath() -> URL? {
        FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
    
    private func getImagePath(key: String) -> URL? {
        guard let folder = getFolderPath() else { return nil }
        return folder.appendingPathComponent(key + ".jpg")
    }
    
    func add(key: String, value: UIImage) {
        guard
            let data = value.jpegData(compressionQuality: 0.5),
            let url = getImagePath(key: key) else { return }
        
        do {
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func get(key: String) -> UIImage? {
        guard
            let url = getImagePath(key: key),
            FileManager.default.fileExists(atPath: url.path()) else { return nil }
        return UIImage(contentsOfFile: url.path())
    }
    
    func delete(key: String) {
        guard let url = getImagePath(key: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
