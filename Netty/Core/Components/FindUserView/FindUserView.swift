//
//  FindUserView.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import SwiftUI
import CloudKit

struct FindUserView: View {
    
    // View Model
    @StateObject private var vm: FindUserViewModel
    
    // Quantity of showed users
    @State private var foundResultCount: Int = 7
    
    // Show more/less button text
    private var buttonText: ButtonText {
        if vm.foundArray.count <= 7 {
            return .none
        } else if vm.foundArray.count > foundResultCount {
            return .more
        } else {
            return .less
        }
    }
    
    // Shows clear recents confirmation dialog if true
    @State private var showConfirmationDialog: Bool = false
    
    enum ButtonText: String {
        case less = "Show less"
        case more = "Show more"
        case none
    }
    
    // Navigation path for navigation view
    @Binding private var path: NavigationPath
    
    // Shows new message sheet
    @Binding private var showSheet: Bool
    
    init(id: CKRecord.ID?, path: Binding<NavigationPath>, showSheet: Binding<Bool>) {
        _vm = .init(wrappedValue: FindUserViewModel(id: id))
        self._path = path
        self._showSheet = showSheet
    }
    
    var body: some View {
        NavigationStack {
            
            List {
                
                if vm.showRecents && !vm.recentsArray.isEmpty {
                    
                    recentsSection
                    
                } else if vm.showFound {
                    
                    if vm.foundArray.isEmpty {
                        
                        nothingFound
                        
                    } else {
                        
                        foundResultsSection
                        
                        if buttonText != .none {
                            
                            buttonView
                            
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
    }
    
    // Show more/less button
    private var buttonView: some View {
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
    
    // Found results
    private var foundResultsSection: some View {
        ForEach(vm.foundArray.prefix(foundResultCount)) { userModel in
            Button {
                showSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    path.append(userModel)
                }
            } label: {
                UserRow(model: userModel)
            }
        }
    }
    
    // Recent users in search
    private var recentsSection: some View {
        Section {
            ForEach(vm.recentsArray) { userModel in
                Button {
                    showSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        path.append(userModel)
                    }
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
    }
    
    // Nothing found view
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
            FindUserView(id: .init(recordName: "F56C48BA-49CE-404D-87CC-4B6407D35089"), path: .constant(.init()), showSheet: .constant(true))
        }
    }
}
