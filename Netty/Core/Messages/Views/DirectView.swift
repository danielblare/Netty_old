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
    
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    
                    ZStack {
                        if vm.chatsArray.isEmpty && !vm.isLoading && !vm.isRefreshing {
                            VStack {
                                Image(systemName: "xmark.bin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80)
                                
                                Text("You don't have any chats yet")
                                    .font(.title3)
                                    .padding()
                            }
                            .foregroundColor(.secondary)
                        } else {
                            List(vm.chatsArray) { chat in
                                HStack {
                                    ProfileImageView(for: chat.id)
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
                            .padding(.top)
                            .listStyle(.inset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .disabled(vm.isLoading)
                    
                    if vm.isLoading {
                        ProgressView()
                    }
                }
                .refreshable {
                    Task {
                        await vm.fullSync()
                    }
                }
                .navigationTitle("Messages")
            }
        }
        
    }
    
    
    
    
}




struct DirectView_Previews: PreviewProvider {
    static var previews: some View {
        DirectView(userRecordId: CKRecord.ID(recordName: "2BF042AD-D7B5-4AEE-9328-D328E942B0FF"))
        DirectView(userRecordId: CKRecord.ID(recordName: "3AF89E4F-8FFA-46CA-A2D3-D6268C5AF11C"))
    }
}
