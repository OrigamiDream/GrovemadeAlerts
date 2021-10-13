//
//  CodableModels.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/07.
//

import Foundation

protocol CodableExportable {
    
    associatedtype Codable
    
    var toCodable: Codable { get }
    
}

protocol CodableImportable {
    
    associatedtype Element
    
    var toElement: Element { get }
    
}

struct CodableProduct: Codable {
    let id: String
    let name: String
    let image: URL?
    let quantity: UInt
    let state: ProductState
}

struct CodableOrder: Codable {
    let id: String
    let orderID: String
    let email: String
    let state: OrderState
    let placedDate: String
    let completionDate: String?
    let products: [CodableProduct]
    let shippedPackages: CodableShippedPackages?
}

struct CodableModel: Codable {
    let orders: [CodableOrder]
    let sortingOption: SortingOption
    let sortAscending: Bool
}

struct CodableShippedPackages: Codable {
    let trackingNumber: String
    let status: String
    let estimatedDelivery: String
    let location: String
}

extension CodableProduct: CodableImportable {
    
    var toElement: Product {
        Product(id: UUID(uuidString: id)!, name: name, image: image, quantity: quantity, state: state)
    }
    
}

extension CodableOrder: CodableImportable {
    
    var toElement: Order {
        let order = Order(id: UUID(uuidString: id)!, orderID: orderID, email: email, state: state, placedDate: placedDate, completionDate: completionDate, shippedPackages: shippedPackages?.toElement)
        order.products = products.map { $0.toElement }
        return order
    }
    
}

extension CodableModel: CodableImportable {
    
    var toElement: Model {
        let model = Model()
        model.orders = orders.map { $0.toElement }
        model.sortingOption = sortingOption
        model.sortAscending = sortAscending
        return model
    }
    
}

extension CodableShippedPackages: CodableImportable {
    
    var toElement: ShippedPackages {
        ShippedPackages(trackingNumber: trackingNumber, status: status, estimatedDelivery: estimatedDelivery, location: location)
    }
    
}
