//
//  HomeView.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
    
    @StateObject private var vm = HomeViewModel()
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Button {
                Task {
                    withAnimation {
                        isLoading = true
                    }
                    await logInAndOutViewModel.logOut()
                    isLoading = false
                }
            } label: {
                Text("Log out")
                    .padding(.horizontal, 100)
                    .padding(.vertical)
                    .background(Rectangle().cornerRadius(15).foregroundColor(.gray.opacity(0.3)))
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
