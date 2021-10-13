//
//  Product.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

enum ProductState: Int, Codable {
    case inProduction = 0
//    case manufactured = 1
    case shipped = 2
    
    var description: String {
        switch self {
        case .inProduction:
            return "In Production"
        case .shipped:
            return "Shipped"
        }
    }
}

class Product: Identifiable, ObservableObject {
    
    let id: UUID
    @Published var name: String
    @Published var image: URL?
    @Published var quantity: UInt
    @Published var state: ProductState
    
    var displayName: String {
        return name.components(separatedBy: "SKU:").first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ": TBD", with: "") ?? "Invalid"
    }
    
    init(id: UUID, name: String, image: URL?, quantity: UInt, state: ProductState) {
        self.id = id
        self.name = name
        self.image = image
        self.quantity = quantity
        self.state = state
    }
}

extension Product: CodableExportable {
    
    var toCodable: CodableProduct {
        CodableProduct(id: id.uuidString, name: name, image: image, quantity: quantity, state: state)
    }
    
}
