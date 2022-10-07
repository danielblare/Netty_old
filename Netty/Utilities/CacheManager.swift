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
    
    func clean(_ cache: NSCache<NSString, NSString>) {
        cache.removeAllObjects()
    }
    
    func clean(_ cache: NSCache<NSString, UIImage>) {
        cache.removeAllObjects()
    }
    
    func addTo(_ cache: NSCache<NSString, NSString>, key: String, value: NSString) {
        cache.setObject(value, forKey: key as NSString)
    }
    
    func addTo(_ cache: NSCache<NSString, UIImage>, key: String, value: UIImage) {
        cache.setObject(value, forKey: key as NSString)
    }
    
    func getFrom(_ cache: NSCache<NSString, UIImage>, key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func getFrom(_ cache: NSCache<NSString, NSString>, key: String) -> NSString? {
        cache.object(forKey: key as NSString)
    }
}
