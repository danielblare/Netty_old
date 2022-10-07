//
//  FindUserView.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import SwiftUI
import CloudKit

struct FindUserView: View {
    
    @ObservedObject private var vm: FindUserViewModel
    
    init(id: CKRecord.ID?) {
        self.vm = FindUserViewModel(id: id)
    }
    
    var body: some View {
        List {
            if vm.showRecents {
                Section("Recents") {
                    ForEach(vm.dataArray) { userModel in
                        UserRow(model: userModel)
                    }
                }
            } else if vm.showFinded {
                if vm.dataArray.isEmpty {
                    nothingFound
                } else {
                    ForEach(vm.dataArray) { userModel in
                        UserRow(model: userModel)
                    }
                }
            }
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onReceive(vm.$searchText.debounce(for: 0.5, scheduler: RunLoop.main), perform: { _ in
            Task {
                await vm.executeQuery()
            }
        })
        .onReceive(vm.$searchText, perform: { _ in
            vm.searchTextChanged()
        })
        .listStyle(.plain)
        .navigationTitle("New message")
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}, message: {
            Text(vm.alertMessage)
        })
    }
    
    private var nothingFound: some View {
        Text("Nothing found...")
            .foregroundColor(.secondary)
            .font(.title3)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowSeparator(.hidden)
    }
}






struct FindUserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FindUserView(id: .init(recordName: "7C21B420-2449-22D0-1F26-387A189663EA"))
        }
    }
}
