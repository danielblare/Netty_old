//
//  PostView.swift
//  Netty
//
//  Created by Danny on 11/6/22.
//

import SwiftUI

struct PostView: View {
    
    @StateObject private var vm: PostViewModel
    
    private let isYours: Bool
    @State private var showConfDialog: Bool = false
    
    init(postModel: PostModel, isYours: Bool) {
        _vm = .init(wrappedValue: PostViewModel(postModel: postModel))
        self.isYours = isYours
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    ProfileImageView(for: vm.postModel.ownerId)
                        .frame(width: 40, height: 40)
                        .padding(.leading, 10)
                    
                    if let nickname = vm.nickname {
                        Text(nickname)
                            .font(.callout)
                            .fontWeight(.semibold)
                    } else {
                        LoadingAnimation()
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        showConfDialog = true
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 10)
                
                Image(uiImage: vm.postModel.photo)
                    .resizable()
                    .scaledToFit()
                
                HStack {
                    
                    Button {
                        vm.liked.toggle()
                    } label: {
                        Image(systemName: vm.liked ? "heart.fill" : "heart")
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "message")
                    }
                    
                    
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        vm.saved.toggle()
                    } label: {
                        Image(systemName: vm.saved ? "bookmark.fill" : "bookmark")
                    }
                }
                .font(.title)
                .padding(10)
            }
        }
        .navigationTitle(vm.nickname ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("", isPresented: $showConfDialog, titleVisibility: .hidden) {
            Button("Delete", role: .destructive, action: {})
            
            Button("Cancel", role: .cancel, action: {})
        }
    }
}

struct PostView_Previews: PreviewProvider {
    
    static let post = PostModel(id: .init(recordName: "3F744AF1-0FB3-4395-A0CA-C8AC9FC5722A"), ownerId: .init(recordName: "A6244FDA-A0DA-47CB-8E12-8F2603271899"), photo: UIImage(named: "testImage")!, creationDate: .now)

    static var previews: some View {
        NavigationView {
            PostView(postModel: post, isYours: true)
                .previewLayout(.sizeThatFits)
        }
    }
}
