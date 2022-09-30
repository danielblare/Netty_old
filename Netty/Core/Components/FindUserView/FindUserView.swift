//
//  FindUserView.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import SwiftUI

struct FindUserView: View {
    
    @StateObject private var vm: FindUserViewModel = FindUserViewModel()
    
    var body: some View {
        List {
            ForEach(vm.dataArray) { userModel in
                UserRow(model: userModel)
            }
        }
        .listStyle(.plain)
    }
}






struct FindUserView_Previews: PreviewProvider {
    static var previews: some View {
        FindUserView()
    }
}
