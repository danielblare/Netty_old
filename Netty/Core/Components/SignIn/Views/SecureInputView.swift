//
//  SecureInputView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct SecureInputView: View {
    
    @State private var isSecured: Bool = true
    @Binding private var text: String
    private var title: String
    private let completion: (() -> Void)?
    
    enum FocusedValue {
        case secure, text
    }
    
    @FocusState private var activeField: FocusedValue?
    
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
                    .textContentType(.password)
                    .keyboardType(.asciiCapable)
                    .focused($activeField, equals: .secure)
                    .frame(minHeight: 25)
                    .padding()
                    .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                        activeField = .secure
                    })
                    .animation(.none, value: isSecured)

                } else {
                    TextField(title, text: $text) {
                        guard let completion = completion else { return }
                        completion()
                    }
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .focused($activeField, equals: .text)
                    .frame(minHeight: 25)
                    .padding()
                    .background(Color.secondary.opacity(0.3).cornerRadius(15).onTapGesture {
                        activeField = .text
                    })
                    .animation(.none, value: isSecured)
                }
            }
            icon
                .onTapGesture {
                    withAnimation(.linear(duration: 0.09)) {
                        isSecured.toggle()
                    }
                }
        }
    }
    
    private var icon: some View {
        Image(systemName: self.isSecured ? "eye.slash" : "eye")
            .accentColor(.gray)
            .padding()
            .background(Color.secondary.opacity(0.0001))
    }
}
