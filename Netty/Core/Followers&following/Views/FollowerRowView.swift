//
//  FollowerRowView.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI

struct FollowerRowView: View {
    
    let model: UserModel
    
    init(model: UserModel, isFollowed: Bool) {
        self.model = model
        self.isFollowed = isFollowed
    }
    
    @State private var isFollowed: Bool
    
    var body: some View {
        NavigationLink(value: UserModelHolderWithDestination(destination: .profile, userModel: model)) {
            HStack {
                ProfileImageView(for: model.id)
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.nickname)
                        .lineLimit(1)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(model.firstName) \(model.lastName)")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .font(.subheadline)
                }
                
                Spacer(minLength: 0)
                
                
                Button {
                    isFollowed.toggle()
                } label: {
                    Text(isFollowed ? "Unfollow" : "Follow")
                        .frame(minWidth: 67)
                }
                .modifier(FollowButton(isFollowed: isFollowed))
                .padding(.leading)
            }
        }
    }
    
    struct FollowButton: ViewModifier {
        
        let isFollowed: Bool
        
        @Namespace private var namespace
        
        func body(content: Content) -> some View {
            if isFollowed {
                content
                    .buttonStyle(.bordered)
            } else {
                content
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct FollowerRowView_Previews: PreviewProvider {
    static var previews: some View {
        FollowerRowView(model: TestUser.userModel, isFollowed: true)
    }
}
