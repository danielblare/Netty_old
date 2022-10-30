//
//  FindUserView.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import SwiftUI
import CloudKit

struct FindUserView: View {
    
    @StateObject private var vm: FindUserViewModel
    @State private var foundResultCount: Int = 7
    private var buttonText: ButtonText {
        if vm.foundArray.count <= 7 {
            return .none
        } else if vm.foundArray.count > foundResultCount {
            return .more
        } else {
            return .less
        }
    }
    
    @State private var showConfirmationDialog: Bool = false
    
    enum ButtonText: String {
        case less = "Show less"
        case more = "Show more"
        case none
    }
    
    init(id: CKRecord.ID?) {
        _vm = .init(wrappedValue: FindUserViewModel(id: id))
    }
    
    var body: some View {
        List {
            if vm.showRecents && !vm.recentsArray.isEmpty {
                Section {
                    ForEach(vm.recentsArray) { userModel in
                        NavigationLink {
                            ChatView(for: userModel, ownId: vm.id)
                        } label: {
                            UserRow(model: userModel)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recents")
                        
                        Spacer(minLength: 0)
                        
                        Button {
                            showConfirmationDialog = true
                        } label: {
                            Text("Clear all")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else if vm.showFound {
                if vm.foundArray.isEmpty {
                    nothingFound
                } else {
                    ForEach(vm.foundArray.prefix(foundResultCount)) { userModel in
                        NavigationLink {
                            Text(userModel.firstName)
                        } label: {
                            UserRow(model: userModel)
                        }
                    }
                    if buttonText != .none {
                        Button(buttonText.rawValue) {
                            withAnimation {
                                if buttonText == .more {
                                    foundResultCount += 5
                                } else {
                                    foundResultCount = 7
                                }
                            }
                        }
                        .foregroundColor(.accentColor)
                        .font(.callout)
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you clear all recents?", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
            Button("Clear") {
                Task {
                    await vm.clearRecents()
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
