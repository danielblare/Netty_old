//
//  HomeViewModel.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI
import CloudKit

class HomeViewModel: ObservableObject {
    
    let userId: CKRecord.ID
    
    init(_ userId: CKRecord.ID) {
        self.userId = userId
    }
}
