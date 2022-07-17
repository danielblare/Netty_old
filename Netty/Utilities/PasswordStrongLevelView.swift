//
//  PasswordStrongLevelView.swift
//  Netty
//
//  Created by Danny on 17/07/2022.
//

import SwiftUI

struct PasswordStrongLevelView: View {
    
    @Binding private var level: PasswordStrongLevel
    private let weakColor: Color = .red
    private let mediumColor: Color = .orange
    private let strongColor: Color = .yellow
    private let veryStrongColor: Color = .green
    private var text: String {
        switch level {
        case .none:
            return ""
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        case .veryStrong:
            return "Very strong"
        }
    }

    init(level: Binding<PasswordStrongLevel>) {
        self._level = level
    }
    
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
                        
            dividers
                .overlay(overlayView.mask(dividers))
            
            Text(text)
                .font(.caption)
                .padding(.trailing, 5)
                .animation(.none, value: level)
        }
        
        .padding(.horizontal, 10)
    }
    
    private var overlayView: some View {
        GeometryReader { geo in
            HStack {
                Spacer(minLength: 0)
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: CGFloat(4 - level.rawValue) / 4 * geo.size.width)

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
    
    @State private static var level: PasswordStrongLevel = .veryStrong
    
    static var previews: some View {
        PasswordStrongLevelView(level: $level)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
