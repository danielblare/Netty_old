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
    
    var photoCache: NSCache<NSString, UIImage> = {
        
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 200
        return cache
    }()
    
    var textCache: NSCache<NSString, NSString> = {
        
        var cache = NSCache<NSString, NSString>()
        cache.countLimit = 200
        cache.totalCostLimit = 1024 * 1024 * 20
        return cache
    }()
    
    func crean() {
        photoCache.removeAllObjects()
        textCache.removeAllObjects()
    }
    
    func add(key: String, value: UIImage) {
        photoCache.setObject(value, forKey: key as NSString)
    }
    
    func add(key: String, value: NSString) {
        textCache.setObject(value, forKey: key as NSString)
    }
    
    func getImage(key: String) -> UIImage? {
        photoCache.object(forKey: key as NSString)
    }
    
    func getText(key: String) -> NSString? {
        textCache.object(forKey: key as NSString)
    }
}
