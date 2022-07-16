//
//  UserModel.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import Foundation
import SwiftUI

struct UserModel: Codable {
    let firstName, lastName, email, nickname: String
    let dateOfBirth: Date
    let avatar: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, nickname, dateOfBirth, avatar
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.email = try container.decode(String.self, forKey: .email)
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.dateOfBirth = try container.decode(Date.self, forKey: .dateOfBirth)
        self.avatar = UIImage(data: try container.decode(Data.self, forKey: .avatar))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(email, forKey: .email)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        if let image = avatar,
            let imageData = image.pngData() {
            try container.encode(imageData, forKey: .avatar)
        }
    }
    
}
