//
//  NumbersOnly.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

class NumbersOnly: ObservableObject {
    @Published var value = "" {
        didSet {
            let filtered = value.filter { $0.isNumber || $0 == "-" }
            if filtered != value {
                value = filtered
            }
        }
    }
}
