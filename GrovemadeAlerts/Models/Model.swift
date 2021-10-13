//
//  Model.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI
import Combine

enum SortingOption: String, CaseIterable, Codable {
    case state = "Progress"
    case email = "Email"
}

struct GrovemadeRetrievalInfo {
    let response: GrovemadeResponse
    let success: Bool
    let order: Order
    let shippedPackages: ShippedPackages?
}

class Model: ObservableObject {
    
    @Published var orders: [Order]
    @Published var sortingOption = SortingOption.state
    @Published var sortAscending = true
    
    init() {
        orders = []
    }
    
    #if DEBUG
    fileprivate init(orders: [Order]) {
        self.orders = orders
    }
    #endif
    
    func save() {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(toCodable)
            UserDefaults.standard.set(encoded, forKey: grovemadeModelKey)
            print("Model has been saved (\(encoded.count) bytes)")
        } catch {
            print("Unexpected error on save: \(error)")
        }
    }
    
    func keys<T>(_ keyPath: KeyPath<Order, T>) -> [T] where T: Comparable {
        return orders.reduce([]) { caches, order in
            return caches.contains(order[keyPath: keyPath]) ? caches : caches + [order[keyPath: keyPath]]
        }.sorted { lhs, rhs in
            if sortAscending {
                return lhs < rhs
            } else {
                return lhs > rhs
            }
        }
    }
    
    func removeOrder<T>(_ index: IndexSet, _ keyPath: KeyPath<Order, T>, key: T) where T: Comparable {
        let uuids = orders.filter { $0[keyPath: keyPath] == key }
            .enumerated()
            .filter { (offset, _) in index.contains(offset) }
            .map { (_, order) in order.id }
        
        let before = orders.count
        withAnimation {
            orders.removeAll { order in
                return uuids.contains(order.id)
            }
            objectWillChange.send()
        }
        let after = orders.count
        print("\(before - after) items are removed")
        save()
    }
    
    @discardableResult
    func refresh() -> Int {
        let before = DispatchTime.now()
        
        let group = DispatchGroup()
        var responses = [(response: GrovemadeResponse, success: Bool, order: Order)]()
        
        for order in orders {
            group.enter()
            
            let dispatchQueue = DispatchQueue(label: "grovemade-retrieval-queue-\(order.orderID)")
            DispatchQueue(label: "grovemade-retrieval-refresh-\(order.orderID)").async {
                let retrievalGroup = DispatchGroup()
                retrievalGroup.enter()
                
                var done: AnyCancellable?
                var result: GrovemadeResponse?
                var success = false
                
                let subject = PassthroughSubject<GrovemadeResponse, Error>()
                retrieveOrderInformationFromGrovemade(queue: dispatchQueue, subject: subject, orderID: order.orderID, email: order.email)
                done = subject.sink { completion in
                    switch completion {
                    case .finished:
                        success = true
                    case .failure(_):
                        success = false
                    }
                    retrievalGroup.leave()
                } receiveValue: { response in
                    result = response
                }
                assert(done != nil)
                retrievalGroup.wait()
                
                if let result = result {
                    responses += [(result, success, order)]
                }
                
                group.leave()
            }
        }
        
        group.wait()
        
        let refreshed = responses.map { (response, success, order) -> GrovemadeRetrievalInfo in
            var shippedPackages: ShippedPackages? = nil
            if let trackingNumber = response.trackingNumber,
               let status = response.deliveryStatus,
               let estimatedDelivery = response.estimatedDelivery,
               let location = response.deliveryLocation {
                
                shippedPackages = ShippedPackages(trackingNumber: trackingNumber, status: status, estimatedDelivery: estimatedDelivery, location: location)
            }
            return GrovemadeRetrievalInfo(response: response, success: success, order: order, shippedPackages: shippedPackages)
        }.reduce(0) { (result, retrievalInfo) -> Int in
            let order = retrievalInfo.order
            let newState = OrderState.fromProducts(shippedPackages: retrievalInfo.shippedPackages, products: retrievalInfo.response.products, completionDate: retrievalInfo.response.completionDate)
            if retrievalInfo.success && (!order.isEquivalent(otherProducts: retrievalInfo.response.products) || order.placedDate != retrievalInfo.response.placedDate || order.completionDate != retrievalInfo.response.completionDate || order.state != newState || order.shippedPackages != retrievalInfo.shippedPackages) {
                DispatchQueue.main.async {
                    withAnimation {
                        order.products = retrievalInfo.response.products
                        order.placedDate = retrievalInfo.response.placedDate
                        order.completionDate = retrievalInfo.response.completionDate
                        order.state = newState
                        order.shippedPackages = retrievalInfo.shippedPackages
                        order.isUpdated = true
                    }
                }
                return result + 1
            }
            return result
        }
        if refreshed > 0 {
            save()
        }
        let after = DispatchTime.now()
        let diff = after.uptimeNanoseconds - before.uptimeNanoseconds
        let milliseconds = Int(diff / UInt64(1_000_000))
        print("Refreshing orders took \(milliseconds)ms")
        return refreshed
    }
}

extension Model: CodableExportable {
    
    var toCodable: CodableModel {
        CodableModel(orders: orders.map { $0.toCodable }, sortingOption: sortingOption, sortAscending: sortAscending)
    }
    
}

#if DEBUG
let modelInstance = Model(orders: [
    Order(id: UUID(), orderID: "23657", email: "j.appleseed@icloud.com", state: .ordered, products: [
        Product(id: UUID(), name: "Wood Desk Shelf: Walnut", image: URL(string: "https://www.grovemade.com/media/shop/variant/walnut-desk-02-shelf-gridcrop-A2.jpg"), quantity: 1, state: .inProduction),
        Product(id: UUID(), name: "Magic Trackpad Tray", image: nil, quantity: 1, state: .inProduction)
    ]),
    Order(id: UUID(), orderID: "73624", email: "j.appleseed@icloud.com", state: .manufacturing, products: [
        Product(id: UUID(), name: "Laptop Riser: Walnut", image: nil, quantity: 1, state: .inProduction),
        Product(id: UUID(), name: "Wool Felt", image: nil, quantity: 1, state: .inProduction),
        Product(id: UUID(), name: "Desk Tray: Walnut", image: nil, quantity: 1, state: .inProduction)
    ]),
    Order(id: UUID(), orderID: "47098", email: "j.appleseed@icloud.com", state: .shipped, products: [
        Product(id: UUID(), name: "Wood Headphone Stand", image: nil, quantity: 1, state: .shipped),
    ], isUpdated: true),
    Order(id: UUID(), orderID: "25227", email: "j.appleseed@icloud.com", state: .delivered, products: [
        Product(id: UUID(), name: "Wood Wall Shelf 54\": Walnut", image: nil, quantity: 2, state: .shipped),
    ]),
    Order(id: UUID(), orderID: "19533", email: "j.appleseed@icloud.com", state: .delivered, products: [
        Product(id: UUID(), name: "Brass and Walnut Pen Stand Set", image: nil, quantity: 1, state: .shipped),
        Product(id: UUID(), name: "Brass Notepad", image: nil, quantity: 1, state: .shipped)
    ])
])
#endif
