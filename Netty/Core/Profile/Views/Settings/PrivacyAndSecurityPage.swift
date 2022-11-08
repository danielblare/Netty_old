//
//  PrivacyAndSecurityPage.swift
//  Netty
//
//  Created by Danny on 11/8/22.
//

import SwiftUI

struct PrivacyAndSecurityPage: View {
    var body: some View {
        List {
            NavigationLink {
                ForgotPasswordEmailPageView()
            } label: {
                HStack {
                    Text("Change password")
                    
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    
                    Spacer(minLength: 0)
                }
                .foregroundColor(.accentColor)
            }

        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyAndSecurityPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyAndSecurityPage()
        }
    }
}
