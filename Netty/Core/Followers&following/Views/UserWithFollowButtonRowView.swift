//
//  UserWithFollowButtonRowView.swift
//  Netty
//
//  Created by Danny on 11/9/22.
//

import SwiftUI

struct UserWithFollowButtonRowView: View {
    
    private let model: UserModel
    @State private var isLoading: Bool = false
    private let followFunc: (UserModel) async -> Result<Void, Error>
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    private let unfollowFunc: (UserModel) async -> Result<Void, Error>
    
    init(model: UserModel, isFollowed: Bool, followFunc: @escaping (UserModel) async -> Result<Void, Error>, unfollowFunc: @escaping (UserModel) async -> Result<Void, Error>) {
        self.model = model
        self.isFollowed = isFollowed
        self.followFunc = followFunc
        self.unfollowFunc = unfollowFunc
    }
    
    @State private var isFollowed: Bool
    
    var body: some View {
        NavigationLink(value: UserModelHolderWithDestination(destination: .profile, userModel: model)) {
            HStack {
                ProfileImageView(for: model.id)
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.nickname)
                        .lineLimit(1)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(model.firstName) \(model.lastName)")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .font(.subheadline)
                }
                
                Spacer(minLength: 0)
                
                
                FollowButton
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
                .disabled(isLoading)
                .padding(.leading)
            }
        }
        .alert(Text(alertTitle), isPresented: $showAlert, actions:{}) {
            Text(alertMessage)
        }
    }
    
    private var FollowButton: some View {
        Button {
            if isFollowed {
                Task {
                    await MainActor.run {
                        isLoading = true
                    }
                    
                    switch await unfollowFunc(model) {
                    case .success(_):
                        await MainActor.run {
                            isFollowed = false
                        }
                    case .failure(let error):
                        HapticManager.instance.notification(of: .error)
                        showAlert(title: "Error while unfollowing", message: error.localizedDescription)
                    }
                    await MainActor.run {
                        withAnimation {
                            isLoading = false
                        }
                    }
                }

            } else {
                Task {
                    await MainActor.run {
                        isLoading = true
                    }
                    
                    switch await followFunc(model) {
                    case .success(_):
                        await MainActor.run {
                            isFollowed = true
                        }
                    case .failure(let error):
                        HapticManager.instance.notification(of: .error)
                        showAlert(title: "Error while following", message: error.localizedDescription)
                    }
                    await MainActor.run {
                        withAnimation {
                            isLoading = false
                        }
                    }
                }

            }
        } label: {
            Text(isFollowed ? "Unfollow" : "Follow")
                .frame(minWidth: 67)
        }
        .followButtonStyle(isFollowed: isFollowed)
    }
        
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            alertTitle = title
            alertMessage = message
            showAlert = true
        }
    }
}

struct UserWithFollowButtonRowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List {
                UserWithFollowButtonRowView(model: TestUser.anastasia, isFollowed: true, followFunc: lol, unfollowFunc: lol)
            }
        }
    }
    
    enum Errork: Error {
        case lol
    }
    
    static func lol(_ user: UserModel) async -> Result<Void, Error> {
        try? await Task.sleep(for: .seconds(1))
        return Result.failure(Errork.lol)
    }
}
