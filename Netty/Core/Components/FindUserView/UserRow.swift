//
//  UserRow.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import SwiftUI

struct UserRow: View {
    
    let model: UserModel
    
    var body: some View {
            HStack {
                ProfileImageView(for: model.id)
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(model.nickname)
                        .lineLimit(1)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(model.firstName) \(model.lastName)")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
}

struct UserRow_Previews: PreviewProvider {
    static var previews: some View {
        UserRow(model: .init(id: TestUser.daniel.id, firstName: TestUser.daniel.firstName, lastName: TestUser.daniel.lastName, nickname: TestUser.daniel.nickname, followers: TestUser.daniel.followers, following: TestUser.daniel.following))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
