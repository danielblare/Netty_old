//
//  AvailabilityCheckManager.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import Foundation
import SwiftUI
import Combine

actor AvailabilityCheckManager {
    
    static let instance = AvailabilityCheckManager()
    private init() {}
    
    /// Checks availability of the nickname
    func checkAvailability(for nickname: String) async -> Bool {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Delay simulation
        
        return nickname.hasPrefix("stuffed")
    }
}
