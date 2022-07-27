//
//  MainScreenView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI

struct MainScreenView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                }
                .tag(0)
            DirectView()
                .tabItem {
                    Image(systemName: "ellipsis.bubble")
                }
                .tag(1)
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                }
                .tag(2)
        }
    }
}








struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
            .preferredColorScheme(.dark)
        MainScreenView()
            .preferredColorScheme(.light)
    }
}
