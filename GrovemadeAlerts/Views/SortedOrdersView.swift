//
//  SortedOrdersView.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct SortedOrdersView<C>: View where C: Hashable & Comparable {
    
    @ObservedObject var model: Model
    
    var keyPath: KeyPath<Order, C>
    var stringValue: (C) -> String
    
    var body: some View {
        ForEach(model.keys(keyPath), id: \.self) { key in
            Section(header: Text(stringValue(key))) {
                ForEach(model.orders.filter { $0[keyPath: keyPath] == key }) { order in
                    NavigationLink(destination: OrderView(order: order)) {
                        OrderRow(order: order)
                    }
                }
                .onDelete { index in
                    model.removeOrder(index, keyPath, key: key)
                }
            }
        }
    }
}

struct SortedOrdersView_Previews: PreviewProvider {
    
    @ObservedObject static var model = modelInstance
    
    static var previews: some View {
        SortedOrdersView(model: model, keyPath: \.state, stringValue: { $0.description })
    }
}
