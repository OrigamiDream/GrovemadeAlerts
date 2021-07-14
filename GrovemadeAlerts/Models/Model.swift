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
        var updated = 0
        let queue = DispatchQueue(label: "grovemade-retrieval-queue")
        orders.filter { $0.state != .delivered }.forEach { order in
            var done: AnyCancellable?
            var products: [Product] = []
            var placedDateString: String?
            var completionDateString: String?
            var success = false
            
            let group = DispatchGroup()
            group.enter()
            
            let subject = PassthroughSubject<GrovemadeResponse, Error>()
            retrieveOrderInformationFromGrovemade(queue: queue, subject: subject, orderID: order.orderID, email: order.email)
            done = subject.sink { completion in
                switch completion {
                case .finished:
                    success = true
                case .failure(_):
                    success = false
                }
                group.leave()
            } receiveValue: { response in
                placedDateString = response.placedDate
                completionDateString = response.completionDate
                products = response.products
            }
            
            group.wait()
            assert(done != nil)
            
            if success && (!order.isEquivalent(otherProducts: products) || order.placedDate != placedDateString || order.completionDate != completionDateString) {
                updated += 1
                DispatchQueue.main.async {
                    withAnimation {
                        order.products = products
                        order.placedDate = placedDateString ?? ""
                        order.completionDate = completionDateString
                        order.isUpdated = true
                    }
                }
            }
        }
        if updated > 0 {
            save()
        }
        return updated
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
        Product(id: UUID(), name: "Desk Shelf", quantity: 1, manufacturedQuantity: 0, shippedQuantity: 0, estimatedShippingDate: "Thursday 08/26/2021", state: .ordered),
        Product(id: UUID(), name: "Magic Trackpad Tray", quantity: 1, manufacturedQuantity: 0, shippedQuantity: 0, estimatedShippingDate: "Thursday 08/26/2021", state: .ordered)
    ]),
    Order(id: UUID(), orderID: "73624", email: "j.appleseed@icloud.com", state: .manufacturing, products: [
        Product(id: UUID(), name: "Laptop Riser: Walnut", quantity: 1, manufacturedQuantity: 1, shippedQuantity: 0, estimatedShippingDate: "Thursday 08/26/2021", state: .manufactured),
        Product(id: UUID(), name: "Wool Felt", quantity: 1, manufacturedQuantity: 0, shippedQuantity: 0, estimatedShippingDate: "Thursday 08/26/2021", state: .manufactured),
        Product(id: UUID(), name: "Desk Tray: Walnut", quantity: 1, manufacturedQuantity: 0, shippedQuantity: 0, estimatedShippingDate: "Thursday 08/26/2021", state: .manufactured)
    ]),
    Order(id: UUID(), orderID: "47098", email: "j.appleseed@icloud.com", state: .shipped, products: [
        Product(id: UUID(), name: "Wood Headphone Stand", quantity: 1, manufacturedQuantity: 1, shippedQuantity: 1, estimatedShippingDate: "Thursday 08/26/2021", state: .shipped),
    ], isUpdated: true),
    Order(id: UUID(), orderID: "25227", email: "j.appleseed@icloud.com", state: .delivered, products: [
        Product(id: UUID(), name: "Wood Wall Shelf 54\": Walnut", quantity: 2, manufacturedQuantity: 2, shippedQuantity: 2, estimatedShippingDate: "Thursday 08/26/2021", state: .shipped),
    ]),
    Order(id: UUID(), orderID: "19533", email: "j.appleseed@icloud.com", state: .delivered, products: [
        Product(id: UUID(), name: "Brass and Walnut Pen Stand Set", quantity: 1, manufacturedQuantity: 1, shippedQuantity: 1, estimatedShippingDate: "Thursday 08/26/2021", state: .shipped),
        Product(id: UUID(), name: "Brass Notepad", quantity: 1, manufacturedQuantity: 1, shippedQuantity: 1, estimatedShippingDate: "Thursday 08/26/2021", state: .shipped)
    ])
])
#endif
