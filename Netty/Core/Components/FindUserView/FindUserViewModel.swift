//
//  FindUserViewModel.swift
//  Netty
//
//  Created by Danny on 9/30/22.
//

import Foundation
import SwiftUI
import CloudKit

class FindUserViewModel: ObservableObject {
    
    @Published var dataArray: [FindUserModel] = []
    
    let dataService = FindUserModelService.instance
    
    init() {
        Task {
            let result = await dataService.downloadData()
            switch result {
            case .success(let dataArray):
                await MainActor.run(body: {
                    self.dataArray = dataArray
                })
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
