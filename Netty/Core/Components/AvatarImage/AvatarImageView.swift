//
//  AvatarImageView.swift
//  Netty
//
//  Created by Danny on 7/28/22.
//

import SwiftUI
import CloudKit

class AvatarImageViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    @Published var isLoading: Bool = false
    
    private let manager = AvatarImageService.instance
    
    init(for id: CKRecord.ID?) {
        getImage(for: id)
    }
    
    func getImage(for id: CKRecord.ID?) {
        guard let id = id else { return }
        isLoading = true
        Task {
            let result = await manager.fetchAvatarForUser(with: id)
            switch result {
            case .success(let image):
                await MainActor.run(body: {
                    self.image = image
                    isLoading = false
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}

struct AvatarImageView: View {
    
    @StateObject var vm: AvatarImageViewModel
    
    init(for id: CKRecord.ID?) {
        _vm = StateObject(wrappedValue: AvatarImageViewModel(for: id))
    }
    
    var body: some View {
        ZStack {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if vm.isLoading {
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            } else {
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.3))
                    .overlay {
                        Image(systemName: "questionmark")
                            .foregroundColor(.secondary)
                    }
            }
        }
    }
}
