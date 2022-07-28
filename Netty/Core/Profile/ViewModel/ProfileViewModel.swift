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
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
    
    init() {
        
    }
    
    func logOut() async {
        await logInAndOutViewModel.logOut()
    }
}
