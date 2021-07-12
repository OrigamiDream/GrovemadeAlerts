//
//  Product.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

enum ProductState: Int, Codable {
    case ordered = 0
    case manufactured = 1
    case shipped = 2
}

class Product: Identifiable, ObservableObject {
    
    let id: UUID
    @Published var name: String
    @Published var quantity: UInt
    @Published var manufacturedQuantity: UInt
    @Published var shippedQuantity: UInt
    @Published var estimatedShippingDate: String
    @Published var state: ProductState
    
    var fulfilledQuantity: UInt {
        switch state {
        case .manufactured:
            return manufacturedQuantity
        case .shipped:
            return shippedQuantity
        case .ordered:
            return 0
        }
    }
    
    var displayName: String {
        return name.components(separatedBy: "SKU:").first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ": TBD", with: "") ?? "Invalid"
    }
    
    init(id: UUID, name: String, quantity: UInt, manufacturedQuantity: UInt, shippedQuantity: UInt, estimatedShippingDate: String, state: ProductState) {
        self.id = id
        self.name = name
        self.estimatedShippingDate = estimatedShippingDate
        self.quantity = quantity
        self.manufacturedQuantity = manufacturedQuantity
        self.shippedQuantity = shippedQuantity
        self.state = state
    }
}

extension Product: CodableExportable {
    
    var toCodable: CodableProduct {
        CodableProduct(id: id.uuidString, name: name, quantity: quantity, manufacturedQuantity: manufacturedQuantity, shippedQuantity: shippedQuantity, estimatedShippingDate: estimatedShippingDate, state: state)
    }
    
}
