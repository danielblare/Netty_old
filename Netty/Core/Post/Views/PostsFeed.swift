//
//  PostsFeed.swift
//  Netty
//
//  Created by Danny on 11/7/22.
//

import SwiftUI

struct PostsFeed: View {
    
    private let posts: [PostModel]
    private let currentPost: PostModel
    private let deleteFunc: ((PostModel) async -> ())?
    
    init(posts: [PostModel], currentPost: PostModel) {
        self.posts = posts
        self.currentPost = currentPost
        self.deleteFunc = nil
    }
    
    init(posts: [PostModel], currentPost: PostModel, deleteFunc: @escaping (PostModel) async -> Void) {
        self.posts = posts
        self.currentPost = currentPost
        self.deleteFunc = deleteFunc
    }

    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(posts) { post in
                    if let deleteFunc = deleteFunc {
                        PostView(postModel: post, deleteFunc: deleteFunc, showNavTitle: true)
                            .id(post.id)
                    } else {
                        PostView(postModel: post, showNavTitle: true)
                            .id(post.id)
                    }
                }
                .onAppear {
                    proxy.scrollTo(currentPost.id)
                }
            }
        }
    }
}

