//
//  ChatView.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI
import CloudKit


struct ChatView: View {
    
    // Presentation mode to dismiss view if error occurred
    @Environment(\.presentationMode) var presentationMode
    
    // View Model
    @StateObject private var vm: ChatViewModel
    
    init(for user: UserModel, ownId: CKRecord.ID?) {
        _vm = .init(wrappedValue: ChatViewModel(user: user, ownId: ownId))
    }
    
    var body: some View {
        GeometryReader { geo in
            
            VStack(spacing: 0) {
                
                ScrollViewReader { proxy in
                    
                    // Chat messages
                    ScrollView(.vertical) {
                        VStack(spacing: 2) {
                            
                            if let chatMessages = vm.chatMessages {
                                ForEach(chatMessages) { chatMessage in
                                    MessageView(chatMessage, geo: geo)
                                        .id(chatMessage.id)
                                        .transition(chatMessage.isCurrentUser ? .move(edge: .bottom) : .opacity)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .onAppear { // Keeps scroll view on the last message
                        goDown(proxy)
                    }
                    .onChange(of: vm.chatMessages?.count) { _ in // Keeps scroll view on the last message
                        goDown(proxy, animated: true)
                        
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                    
                    // Message text field
                    getMessageTextField(proxy)
                }
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
    }
    
    // New message text field with send button
    private func getMessageTextField(_ proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .bottom) {
            TextField("Message", text: $vm.messageTextField, axis: .vertical)
                .padding(.vertical, 6)
                .padding(.leading, 12)
                .onTapGesture {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        goDown(proxy, animated: true)
                    }
                }
            
            Button {
                #warning("Action")
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .padding(.vertical, 1)
            .disabled(vm.messageTextField.isEmpty)
            
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
    
    // Scrolls messages to last one
    private func goDown(_ proxy: ScrollViewProxy, animated: Bool = false) {
        withAnimation(animated ? .default : .none) {
            proxy.scrollTo(vm.chatMessages?.last?.id)
        }
    }
}











struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(for: UserModel(id: .init(recordName: "30E1675A-A59C-4FB4-8A2A-5E99D197E736"), firstName: "Anastasi", lastName: "Zavrak", nickname: "anastasi.a"), ownId: .init(recordName: "7C21B420-2449-22D0-1F26-387A189663EA"))
        }
    }
}
