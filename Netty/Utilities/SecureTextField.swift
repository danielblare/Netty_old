//
//  SecureTextField.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct SecureTextField: View {
    
    private let title: String
    @Binding private var text: String
    private let completion: (() -> Void)?
    @State private var showPassword: Bool = false
    
    init(_ title: String, text: Binding<String>, completion: (() -> Void)? = nil) {
        self.title = title
        self._text = text
        self.completion = completion
    }
    
    var body: some View {
        ZStack {
            if !showPassword {
                SecureField(title, text: $text) {
                    guard let completion = completion else { return }
                    completion()
                }
                .padding(.horizontal)
                .frame(height: 20)
            } else {
                TextField(title, text: $text) {
                    guard let completion = completion else { return }
                    completion()
                }
                .padding(.horizontal)
                .frame(height: 20)
            }
            
            HStack {
                Spacer()
                
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .frame(height: 20)
                    .padding()
                    .background(content: {
                        Rectangle()
                            .cornerRadius(10)
                            .foregroundColor(.secondary.opacity(0.00001))
                    })
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.09)) {
                            showPassword.toggle()
                        }
                }
            }
        }
        
    }
}
