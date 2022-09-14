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
            ZStack {
                ZStack {
                    if vm.chatsArray.isEmpty && !vm.isLoading {
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
                        List {
                            ForEach(vm.chatsArray) { chat in
                                HStack {
                                    // Image
                                    ZStack {
                                        if let image = chat.profileImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle()
                                                .foregroundColor(.secondary.opacity(0.3))
                                                .overlay {
                                                    Image(systemName: "questionmark")
                                                        .foregroundColor(.secondary)
                                                }
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .padding(.horizontal)
                                    
                                    Text(chat.userName)
                                }
                            }
                            
                        }
                    }
                    VStack {
                        Spacer()
                        
                        Button("sync") {
                            Task {
                                await vm.sync()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .disabled(vm.isLoading)
                
                if vm.isLoading {
                    ProgressView()
                }
            }
            .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {}, message: {
                Text(vm.alertMessage)
            })
        }
    }
}




struct DirectView_Previews: PreviewProvider {
    static var previews: some View {
        DirectView(userRecordId: CKRecord.ID(recordName: "2BF042AD-D7B5-4AEE-9328-D328E942B0FF"))
        DirectView(userRecordId: CKRecord.ID(recordName: "3AF89E4F-8FFA-46CA-A2D3-D6268C5AF11C"))
    }
}
