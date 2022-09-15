//
//  DirectView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit

struct DirectView: View {
    
    @ObservedObject private var vm: DirectViewModel
    
    init(userRecordId: CKRecord.ID?) {
        vm = DirectViewModel(userRecordId: userRecordId)
    }
    
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    
                    ZStack {
                        if vm.chatsArray.isEmpty && !vm.isLoading {
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
                                        await vm.fullSync()
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
                        } else if !vm.chatsArray.isEmpty {
                            List(searchResults) { chat in
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
                                .swipeActions(content: {
                                    Button("Delete", role: .destructive) {
                                        Task {
                                            await vm.delete(chat: chat)
                                        }
                                    }
                                })
                            }
                            
                            .listStyle(.inset)
                            .searchable(text: $searchText)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .disabled(vm.isLoading)

                    if vm.isLoading {
                        ProgressView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                       Text("Messages")
                            .fontWeight(.semibold)
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                }
                .refreshable {
                    Task {
                        await vm.fullSync()
                    }
                }
            }
        }
        
    }
    
    private var searchResults: [ChatModel] {
        if searchText.isEmpty {
            return vm.chatsArray
        } else {
            return vm.chatsArray.filter { $0.userName.contains(searchText.lowercased()) }
        }
    }
    
    
}




struct DirectView_Previews: PreviewProvider {
    static var previews: some View {
        DirectView(userRecordId: CKRecord.ID(recordName: "2BF042AD-D7B5-4AEE-9328-D328E942B0FF"))
        DirectView(userRecordId: CKRecord.ID(recordName: "3AF89E4F-8FFA-46CA-A2D3-D6268C5AF11C"))
    }
}
