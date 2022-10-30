//
//  ChatView.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI
import CloudKit


struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm: ChatViewModel
    
    init(for user: FindUserModel, ownId: CKRecord.ID?) {
        _vm = .init(wrappedValue: ChatViewModel(user: user, ownId: ownId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollViewReader { value in
                
                ScrollView {
                    
                    if let chatMessages = vm.chatMessages {
                        ForEach(chatMessages) { chatMessage in
                            Text(chatMessage.message)
                                .id(chatMessage.id)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .onAppear {
                    value.scrollTo(vm.chatMessages?.last?.id)
                }
                .onChange(of: vm.chatMessages?.count) { _ in
                    value.scrollTo(vm.chatMessages?.last?.id)
                    
                }
            }
            
            textField
        }
        .navigationTitle(vm.userModel.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .disabled(vm.isLoading)
        .overlay {
            if vm.isLoading {
                ProgressView()
            }
        }
        .alert(Text(vm.alertTitle), isPresented: $vm.showAlert, actions: {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        }, message: {
            Text(vm.alertMessage)
        })
    }
    
    var textField: some View {
        HStack {
            TextField("Message", text: $vm.messageTextField, axis: .vertical)
                .padding(6)
            Button {
                // fadfaw
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(vm.messageTextField.isEmpty)
            
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}











struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(for: FindUserModel(id: .init(recordName: "30E1675A-A59C-4FB4-8A2A-5E99D197E736"), firstName: "Anastasi", lastName: "Zavrak", nickname: "anastasi.a"), ownId: .init(recordName: "7C21B420-2449-22D0-1F26-387A189663EA"))
        }
    }
}
