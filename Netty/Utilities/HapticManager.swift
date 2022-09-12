//
//  HapticManager.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation
import SwiftUI

class HapticManager {
    
    static let instance = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    func notification(of type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
