//
//  SecureInputView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct SecureInputView: View {
    
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    private let completion: (() -> Void)?
    
    init(_ title: String, text: Binding<String>, completion: (() -> Void)? = nil) {
        self.title = title
        self._text = text
        self.completion = completion
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(title, text: $text) {
                        guard let completion = completion else { return }
                        completion()
                    }
                    .autocorrectionDisabled(true)
                    .textContentType(.newPassword)
                    .frame(minHeight: 25)
                } else {
                    TextField(title, text: $text) {
                        guard let completion = completion else { return }
                        completion()
                    }
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .textContentType(.newPassword)
                    .frame(minHeight: 25)
                }
            }.padding(.trailing, 32)
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
    }
}
