//
//  MessageView.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI

struct MessageView: View {
    
    let message: String
    let isCurrentUser: Bool
    let proxy: GeometryProxy
    
    init(_ chatMessage: ChatMessage, geo: GeometryProxy) {
        message = chatMessage.message
        isCurrentUser = chatMessage.isCurrentUser
        proxy = geo
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isCurrentUser {
                Spacer(minLength: 0)
            }
            
            Text(message)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isCurrentUser ? Color.theme.gradientDark.opacity(0.5).cornerRadius(15) : Color.theme.gradientLight.opacity(0.5).cornerRadius(15))
                .padding(.horizontal)
                .frame(maxWidth: proxy.size.width * 0.78, alignment: isCurrentUser ? .trailing : .leading)

            
            if !isCurrentUser {
                Spacer(minLength: 0)
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            MessageView(ChatMessage(message: "Hello", isCurrentUser: false), geo: geo)
            .previewLayout(.sizeThatFits)
        }
    }
}
