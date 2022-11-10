//
//  MessageView.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI
import CloudKit

struct MessageView: View {
    
    // Message text
    let message: String
    
    // True if message belongs to current user
    let isCurrentUser: Bool
    
    // Geometry proxy
    let proxy: GeometryProxy
    
    init(_ chatMessage: ChatMessageModel, ownId: CKRecord.ID, geo: GeometryProxy) {
        message = chatMessage.message
        isCurrentUser = chatMessage.isCurrentUser(ownId: ownId)
        proxy = geo
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isCurrentUser { // Pushes message to the right is current user sent this message
                Spacer(minLength: 0)
            }
            
            Text(message)
                .textSelection(.enabled)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isCurrentUser ? Color.theme.gradientDark.opacity(0.5).cornerRadius(15) : Color.theme.gradientLight.opacity(0.5).cornerRadius(15))
                .padding(.horizontal)
                .frame(maxWidth: proxy.size.width * 0.78, alignment: isCurrentUser ? .trailing : .leading)

            
            if !isCurrentUser { // Pushes message to the left is current user didn't send this message
                Spacer(minLength: 0)
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            MessageView(ChatMessageModel(userId: TestUser.anastasia.id.recordName, message: "Hello", date: Date()), ownId: TestUser.daniel.id, geo: geo)
            .previewLayout(.sizeThatFits)
        }
    }
}
