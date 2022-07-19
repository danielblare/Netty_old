//
//  LaunchView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI

struct LaunchView: View {
    
    @Binding var showLaunchView: Bool
    @State private var scale: Double = 1
    
    
    var body: some View {
        ZStack {
            Color.theme.gradientDark
                .ignoresSafeArea()
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 350)
                .scaleEffect(scale)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeIn(duration: 0.4)) {
                            showLaunchView = false
                        }
                    }
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 10).repeatCount(10)) {
                        scale = 1.2
                    }
                }
        }
        .scaleEffect(showLaunchView ? 1 : 5)
    }
}








struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView(showLaunchView: .constant(true))
    }
}
