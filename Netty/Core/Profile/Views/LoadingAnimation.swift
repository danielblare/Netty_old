//
//  LoadingAnimation.swift
//  Netty
//
//  Created by Danny on 9/11/22.
//

import SwiftUI

struct LoadingAnimation: View {
    
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    
    @State private var count: Int = 0
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .offset(y: count == 1 ? -3 : 0)
            Circle()
                .offset(y: count == 2 ? -3 : 0)
            Circle()
                .offset(y: count == 3 ? -3 : 0)
        }
        .foregroundColor(.secondary)
        .frame(width: 20, height: 10)
        .onReceive(timer, perform: { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                count = count == 3 ? 0 : count + 1
            }
        })
    }
}

struct LoadingAnimation_Previews: PreviewProvider {
    static var previews: some View {
        LoadingAnimation()
    }
}
