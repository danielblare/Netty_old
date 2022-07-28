//
//  ProfileView.swift
//  Netty
//
//  Created by Danny on 7/27/22.
//

import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    
    @State private var isLoading: Bool = false
    @State private var showSheet: Bool = false
    
    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
    
    @EnvironmentObject private var logInAndOutViewModel: LogInAndOutViewModel
            
    var body: some View {
        ZStack {
            ZStack {
                
                VStack {
                    HStack {
                        
                        ZStack {
                            if let image = vm.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                        .onAppear {
                            vm.getImage(for: logInAndOutViewModel.userRecordId)
                        }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()
                            .onTapGesture {
                                showSheet = true
                            }

                        
                        Spacer(minLength: 0)
                    }
                    
                    
                    Spacer(minLength: 0)
                    
                    
                    Button {
                        Task {
                            isLoading = true
                            await logInAndOutViewModel.logOut()
                            isLoading = false
                        }
                    } label: {
                        Text("Log out")
                            .font(.title2)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.bordered)
                }
                
                
                
            }
            .disabled(isLoading)
            .sheet(isPresented: $showSheet) {
                PhotoPicker() { pickedElements in
                    if let pickedElements = pickedElements {
                        let provider = pickedElements[0].itemProvider
                        if provider.canLoadObject(ofClass: UIImage.self) {
                            provider.loadObject(ofClass: UIImage.self) { object, error in
                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                
                                if let image = object as? UIImage {
                                    vm.uploadImage(image, for: logInAndOutViewModel.userRecordId)
                                }
                            }
                        }
                    }
                    showSheet = false
                }
            }
            
            if isLoading {
                ProgressView()
            }
        }
    }
}


struct PhotoPicker: UIViewControllerRepresentable {
    
    var pickedElements: (_ pickedElements: [PHPickerResult]?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = .any(of: [.images, .livePhotos, .screenshots])
        configuration.selectionLimit = 1
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
      
        private let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if results.isEmpty {
                parent.pickedElements(nil)
            } else {
                parent.pickedElements(results)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(LogInAndOutViewModel())
            .preferredColorScheme(.light)
        ProfileView()
            .environmentObject(LogInAndOutViewModel())
            .preferredColorScheme(.dark)
    }
}
