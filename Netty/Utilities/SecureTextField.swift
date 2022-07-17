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
        ZStack(alignment: .trailing) {
            if !showPassword {
                SecureField(title, text: $text) {
                    guard let completion = completion else { return }
                    completion()
                }
            } else {
                TextField(title, text: $text) {
                    guard let completion = completion else { return }
                    completion()
                }
            }
            
            Image(systemName: showPassword ? "eye.slash" : "eye")
                .frame(height: 25)
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.09)) {
                        showPassword.toggle()
                    }
                }
        }
    }
}
