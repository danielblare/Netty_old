//
//  NettyApp.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI

@main
struct NettyApp: App {
    
    @State private var userSignedIn: Bool = false // Is signed in logic
    @State private var showLaunchView: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if userSignedIn {
                    //                HomeView()
                } else {
                    SignUpView()
                }
                
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                            .transition(.opacity)
                    }
                }
                .zIndex(2.0)
            }
        }
    }
}
