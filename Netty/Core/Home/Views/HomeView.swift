//
//  HomeView.swift
//  Netty
//
//  Created by Danny on 20/07/2022.
//

import SwiftUI
import CloudKit

struct HomeView: View {
        
    // View Model
    @StateObject private var vm: HomeViewModel
    
    @State private var sheetIsPresented: Bool = false
    
    init(userId: CKRecord.ID) {
        _vm = .init(wrappedValue: HomeViewModel(userId))
    }
        
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(1..<100) { _ in
                        Text("News")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .refreshable {
                    #warning("Refreshable")
                }
                .toolbar { getToolbar(proxy) }
            }
            .sheet(isPresented: $sheetIsPresented) {
                NavigationStack {
                    FindUserView(id: vm.userId, forDestination: .profile, finishPickingFunc: findUserFinishPicking)
                        .navigationTitle("Find User")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .padding(.top)
            }
        }
    }
    
    private func findUserFinishPicking() {
        sheetIsPresented = false
    }
    
    // Creates toolbar for navigation view
    @ToolbarContentBuilder private func getToolbar(_ proxy: ScrollViewProxy) -> some ToolbarContent {
        
        // Title
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Feed")
                .onTapGesture {
                    #warning("Scroll to top")
//                    proxy.scrollTo()
                }
                .fontWeight(.semibold)
                .font(.title)
                .foregroundColor(.accentColor)
        }
        
        // New message button
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                sheetIsPresented = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
        }
    }

}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(userId: TestUser.id)
            .preferredColorScheme(.dark)
        HomeView(userId: TestUser.id)
            .preferredColorScheme(.light)
    }
}
