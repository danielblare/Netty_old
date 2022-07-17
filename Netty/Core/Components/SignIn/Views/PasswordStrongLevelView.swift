//
//  PasswordStrongLevelView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

enum PasswordWarningMessage: String {
    case short = "Enter at least 8 symbols"
    case unacceptableSymbols = "Password contains unacceptable symbols"
    case numbersAndLetters = "Password should contain letters and numbers"
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    case veryStrong = "Very strong"
}

struct PasswordStrongLevelView: View {
    
    @Binding private var message: PasswordWarningMessage
    private let weakColor: Color = .red
    private let mediumColor: Color = .orange
    private let strongColor: Color = .yellow
    private let veryStrongColor: Color = .green
    private var segmentsOpened: Int {
        switch message {
        case .weak:
            return 1
        case .medium:
            return 2
        case .strong:
            return 3
        case .veryStrong:
            return 4
        default:
            return 0
        }
    }
    
    init(message: Binding<PasswordWarningMessage>) {
        self._message = message
    }
    
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
                        
            dividers
                .overlay(overlayView.mask(dividers))
            
            Text(message.rawValue)
                .font(.caption)
                .padding(.trailing, 5)
                .animation(.none, value: message)
        }
        
        .padding(.horizontal, 10)
    }
    
    private var overlayView: some View {
        GeometryReader { geo in
            HStack {
                Spacer(minLength: 0)
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: CGFloat(4 - segmentsOpened) / 4 * geo.size.width)

            }
        }
    }
    
    private var dividers: some View {
        HStack {
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .frame(height: 6)
                .foregroundColor(weakColor)
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .frame(height: 6)
                .foregroundColor(mediumColor)
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .frame(height: 6)
                .foregroundColor(strongColor)
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .frame(height: 6)
                .foregroundColor(veryStrongColor)
        }
    }

}

struct PasswordStrongLevelView_Previews: PreviewProvider {
    
    @State private static var message: PasswordWarningMessage = .veryStrong
    
    static var previews: some View {
        PasswordStrongLevelView(message: $message)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
