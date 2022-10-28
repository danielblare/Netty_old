//
//  DirectView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct DirectView: View {
    
    @StateObject private var vm: DirectViewModel
    
    init(userRecordId: CKRecord.ID?) {
        _vm = .init(wrappedValue: DirectViewModel(userRecordId: userRecordId))
    }
    
    @State private var searchText: String = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    HStack {
                        Text("Messages")
                            .fontWeight(.semibold)
                            .font(.title)
                            .foregroundColor(.accentColor)
                        
                        Spacer(minLength: 0)
                        
                        NavigationLink {
                            FindUserView(id: vm.userRecordId)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    ZStack {
                        if vm.chatsArray.isEmpty && !vm.isLoading {
                            noChatsView
                        } else if !vm.chatsArray.isEmpty {
                            List(searchResults) { chat in
                                chatView(for: chat, with: geo)
                                    .swipeActions {
                                        getSwipeActionsFor(chat)
                                    }
                            }
                            
                            .listStyle(.inset)
                            .searchable(text: $searchText)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .disabled(vm.isLoading)

                }
                
                if vm.isLoading {
                    ProgressView()
                }
            }
            .refreshable {
                Task {
                    await vm.sync()
                }
            }
            .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}, message: {
                Text(vm.alertMessage)
            })
        }
    }
    
    private func chatView(for chat: ChatModel, with geo: GeometryProxy) -> some View {
        HStack {
            ProfileImageView(for: chat.opponentId)
                .frame(width: 70, height: 70)
                .padding(.trailing, 5)
            
            VStack(alignment: .leading) {
                Text(chat.userName)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .padding(.top)
                    .frame(width: geo.size.width * 0.5, alignment: .leading)
                
                Spacer(minLength: 0)
                
                Text(chat.lastMessage ?? "...")
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.bottom)
                    .frame(width: geo.size.width * 0.6, alignment: .leading)
            }
        }
    }
    
    private func getSwipeActionsFor(_ chat: ChatModel) -> some View {
        Button("Delete", role: .destructive) {
            Task {
                await vm.delete(chat: chat)
            }
        }
    }
    
    private var noChatsView: some View {
        VStack {
            Image(systemName: "xmark.bin")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
            
            Text("You don't have any chats")
                .font(.title3)
                .padding()
            
            Button {
                Task {
                    await vm.sync()
                }
            } label: {
                Label {
                    Text("Tap to reload")
                } icon: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(vm.isRefreshing ? Angle(degrees: 360) : Angle(degrees: 0))
                }
            }
        }
        .foregroundColor(.secondary)
    }
        
    private var searchResults: [ChatModel] {
        if searchText.isEmpty {
            return vm.chatsArray
        } else {
            return vm.chatsArray.filter { $0.userName.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    
}




struct DirectView_Previews: PreviewProvider {
    static var previews: some View {
        DirectView(userRecordId: CKRecord.ID(recordName: "7C21B420-2449-22D0-1F26-387A189663EA"))
        DirectView(userRecordId: CKRecord.ID(recordName: "7C21B420-2449-22D0-1F26-387A189663EA"))
    }
}
