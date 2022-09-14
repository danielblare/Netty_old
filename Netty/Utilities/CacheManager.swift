//
//  PhotoModelCacheManager.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import Foundation
import SwiftUI

class CacheManager {
    
    static let instance = CacheManager()
    private init() { }
    
    var profilePhotoCache: NSCache<NSString, UIImage> = {
        
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 200
        return cache
    }()
    
    var directPhotoCache: NSCache<NSString, UIImage> = {
        
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 200
        return cache
    }()
    
    var profileTextCache: NSCache<NSString, NSString> = {
        
        var cache = NSCache<NSString, NSString>()
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 20
        return cache
    }()
    
    func cleanProfilePhotoCache() {
        profilePhotoCache.removeAllObjects()
    }
    
    func cleanProfileTextCache() {
        profileTextCache.removeAllObjects()
    }
    
    func cleanDirectPhotoCache() {
        directPhotoCache.removeAllObjects()
    }
    
    func addToProfilePhotoCache(key: String, value: UIImage) {
        profilePhotoCache.setObject(value, forKey: key as NSString)
    }
    
    func addToDirectPhotoCache(key: String, value: UIImage) {
        directPhotoCache.setObject(value, forKey: key as NSString)
    }
    
    func addToProfileTextCache(key: String, value: NSString) {
        profileTextCache.setObject(value, forKey: key as NSString)
    }
    
    func getImageFromDirectCache(key: String) -> UIImage? {
        directPhotoCache.object(forKey: key as NSString)
    }
    
    func getImageFromProfilePhotoCache(key: String) -> UIImage? {
        profilePhotoCache.object(forKey: key as NSString)
    }
    
    func getTextFromProfileTextCache(key: String) -> NSString? {
        profileTextCache.object(forKey: key as NSString)
    }
}
