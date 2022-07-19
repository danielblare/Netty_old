//
//  WelcomeView.swift
//  Netty
//
//  Created by Danny on 19/07/2022.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    NavigationLink("Sign Up") {
                        NamePageView()
                    }
                    NavigationLink("Log In") {
                        EmptyView()
                    }
                }
                .navigationTitle("Welcome to Netty!")
                .background(Color.theme.background)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
