//
//  OrderView.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct OrderView: View {
    
    @ObservedObject var order: Order
    
    var body: some View {
        List {
            Section {
                OrderInfoField(
                    stringValue: .constant(order.orderID),
                    title: "Order ID",
                    placeholder: "Enter the Order ID...",
                    keyboardType: .numbersAndPunctuation,
                    disabled: true,
                    onComplete: { })
                OrderInfoField(
                    stringValue: .constant(order.email),
                    title: "Email",
                    placeholder: "Enter the Email...",
                    keyboardType: .emailAddress,
                    disabled: true,
                    onComplete: { })
            }
            Section {
                OrderRegistrarResult(orderID: order.orderID, placedDate: order.placedDate, completionDate: order.completionDate, progress: .constant(.responded), retrievalResult: .constant(.none))
            }
            Section(header: Text("Ordered Items")) {
                ForEach(order.products) { product in
                    ProductRow(product: product)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("#\(order.orderID)", displayMode: .inline)
        .onAppear {
            order.isUpdated = false
        }
    }
}

struct OrderView_Previews: PreviewProvider {
    static var previews: some View {
        OrderView(order: modelInstance.orders[0])
    }
}