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
        UserRow(model: .init(id: .init(recordName: "B63BEF34-814C-4259-6901-8677FF665F76"), firstName: "Danylo", lastName: "Siefierov", nickname: "stuffeddanny"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
