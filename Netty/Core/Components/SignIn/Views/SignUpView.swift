//
//  SignUpView.swift
//  Netty
//
//  Created by Danny on 16/07/2022.
//

import SwiftUI

struct SignUpView: View {
    
    @StateObject private var vm: SignUpViewModel = SignUpViewModel()

    var body: some View {
        switch vm.registrationLevel {
        case .name:
            NamePageView(vm: vm)
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .email:
            EmailPageView(vm: vm)
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .nickname:
            NicknamePageView(vm: vm)
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .password:
            CreatePasswordPageView(vm: vm)
                .transition(vm.transitionForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                        .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.light)
        SignUpView()
            .preferredColorScheme(.dark)
    }
}
