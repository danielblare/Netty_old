//
//  TestUser.swift
//  Netty
//
//  Created by Danny on 11/10/22.
//

import SwiftUI
import CloudKit

struct TestUser {
    
    static let daniel: UserModel = UserModel(id: .init(recordName: "A6244FDA-A0DA-47CB-8E12-8F2603271899"), firstName: "Daniel", lastName: "Wilson", nickname: "stuffeddanny", followers: [], following: [])
    
    static let anastasia: UserModel = UserModel(id: .init(recordName: "30E1675A-A59C-4FB4-8A2A-5E99D197E736"), firstName: "Anastasia", lastName: "Zavrak", nickname: "anastasi.az", followers: [], following: [])
}
