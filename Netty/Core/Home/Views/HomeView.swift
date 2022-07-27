//
//  HomeView.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI

struct HomeView: View {
        
    @StateObject private var vm = HomeViewModel()
        
    var body: some View {
        Text("Home")
    }
}






struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
        HomeView()
            .preferredColorScheme(.light)
    }
}
