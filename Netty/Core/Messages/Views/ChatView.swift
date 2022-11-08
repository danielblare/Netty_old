//
//  ChatView.swift
//  Netty
//
//  Created by Danny on 10/30/22.
//

import SwiftUI
import CloudKit
import Combine

struct ChatView: View {
    
    @EnvironmentObject private var mainScreenVm: MainScreenViewModel
    
    // Presentation mode to dismiss view if error occurred
    @Environment(\.presentationMode) var presentationMode
    
    // View Model
    @StateObject private var vm: ChatViewModel
    
    init(for user: UserModel, ownId: CKRecord.ID) {
        _vm = .init(wrappedValue: ChatViewModel(user: user, ownId: ownId))
    }
    
    var body: some View {
        GeometryReader { geo in
            
            VStack(spacing: 0) {
                
                ScrollViewReader { proxy in
                    
                    // Chat messages
                    ScrollView(.vertical) {
                        VStack(spacing: 2) {
                            
                            ForEach(vm.chatMessages) { chatMessage in
                                MessageView(chatMessage, ownId: vm.ownId, geo: geo)
                                    .id(chatMessage.id)
                                    .transition(chatMessage.isCurrentUser(ownId: vm.ownId) ? .move(edge: .bottom) : .opacity)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .onAppear { // Keeps scroll view on the last message
                        goDown(proxy)
                    }
                    .onChange(of: vm.chatMessages.count) { _ in // Keeps scroll view on the last message
                        goDown(proxy, animated: true)
                        
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if vm.messageTextField.count > Limits.sendMessageFieldLength - 20 {
                            Text("\(vm.messageTextField.count)/\(Limits.sendMessageFieldLength)")
                                .padding(.trailing)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Message text field
                    getMessageTextField(proxy)
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(vm.userModel.nickname)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            mainScreenVm.path.append(UserModelHolder(destination: .profile, userModel: vm.userModel))
                        }
                }
            }
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
    
    //Function to keep text length in limits
    private func limitText(_ upper: Int) {
        if vm.messageTextField.count > upper {
            vm.messageTextField = String(vm.messageTextField.prefix(upper))
        }
    }
    
    // New message text field with send button
    private func getMessageTextField(_ proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .bottom) {
            TextField("Message", text: $vm.messageTextField, axis: .vertical)
                .onReceive(Just(vm.messageTextField), perform: { _ in
                    limitText(Limits.sendMessageFieldLength)
                })
                .padding(.vertical, 6)
                .padding(.leading, 12)
                .onTapGesture {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        goDown(proxy, animated: true)
                    }
                }
            
            Button {
                Task {
                    await vm.sendMessage()
                }
            } label: {
                Image(systemName: vm.isSending ? "circle.fill" : "arrow.up.circle.fill")
                    .font(.title)
            }
            .padding(.vertical, 1)
            .disabled(vm.messageTextField.isEmpty || vm.isSending)
            .overlay {
                if vm.isSending {
                    ProgressView()
                }
            }
            
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
            proxy.scrollTo(vm.chatMessages.last?.id)
        }
    }
}











struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(for: UserModel(id: .init(recordName: "30E1675A-A59C-4FB4-8A2A-5E99D197E736"), firstName: "Anastasi", lastName: "Zavrak", nickname: "anastasi.a"), ownId: TestUser.id)
        }
    }
}
