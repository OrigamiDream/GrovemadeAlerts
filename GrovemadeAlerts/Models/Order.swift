//
//  Order.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

enum OrderState: Int, Comparable, Codable {
    case shipped = 0
    case manufacturing = 1
    case ordered = 2
    case delivered = 3
    
    var description: String {
        switch self {
        case .shipped:
            return "Shipped"
        case .manufacturing:
            return "Manufacturing"
        case .ordered:
            return "Ordered"
        case .delivered:
            return "Delivered"
        }
    }
    
    static func < (lhs: OrderState, rhs: OrderState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Order: Identifiable, ObservableObject {
    
    let id: UUID
    @Published var orderID: String
    @Published var email: String
    @Published var state: OrderState
    @Published var placedDate: String
    @Published var completionDate: String?
    @Published var products: [Product] = []
    @Published var isUpdated = false
    
    var textDescription: String {
        let productCount = products.compactMap { $0.quantity }.reduce(0, +)
        switch state {
        case .ordered:
            return "Just ordered \(productCount) products from Grovemade."
        case .manufacturing:
            return "\(products.compactMap { $0.manufacturedQuantity }.reduce(0, +)) out of \(productCount) products are being manufactured."
        case .shipped:
            return "\(products.compactMap { $0.shippedQuantity }.reduce(0, +)) out of \(productCount) products had been shipped."
        case .delivered:
            return "\(productCount) products had been delivered."
        }
    }
    
    init(id: UUID, orderID: String, email: String, state: OrderState, placedDate: String, completionDate: String?) {
        self.id = id
        self.orderID = orderID
        self.email = email
        self.state = state
        self.placedDate = placedDate
        self.completionDate = completionDate
    }
    
    #if DEBUG
    convenience init(id: UUID, orderID: String, email: String, state: OrderState, products: [Product]) {
        self.init(id: id, orderID: orderID, email: email, state: state, placedDate: "Your order was placed on March 17, 2021.", completionDate: state == .delivered ? "Order was completed on April 26, 2021." : nil)
        
        self.products = products
    }
    #endif
    
    func isEquivalent(otherProducts: [Product]) -> Bool {
        var equals = true
        for product in products {
            guard let otherProduct = otherProducts.filter({ $0.name == product.name }).first else {
                equals = false
                break
            }
            if product.state != otherProduct.state || product.fulfilledQuantity != otherProduct.fulfilledQuantity {
                equals = false
                break
            }
        }
        return equals
    }
    
}

extension Order: CodableExportable {
    
    var toCodable: CodableOrder {
        CodableOrder(id: id.uuidString, orderID: orderID, email: email, state: state, placedDate: placedDate, completionDate: completionDate, products: products.map { $0.toCodable })
    }
    
}