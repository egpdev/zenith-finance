//
//  Item.swift
//  calculateAI
//
//  Created by Minamino Shuichi on 20.01.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
