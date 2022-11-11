//
//  Date.swift
//  Netty
//
//  Created by Danny on 11/11/22.
//

import Foundation

extension Date {
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
}
