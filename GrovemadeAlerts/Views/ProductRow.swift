//
//  ProductRow.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct ProductRow: View {
    
    var product: Product
    
    var body: some View {
        HStack {
            HStack {
                Text(String(product.fulfilledQuantity))
                    .font(.headline)
                    .offset(y: -6)
                Text("⁄")
                    .font(.title.weight(.light))
                    .foregroundColor(.gray)
                    .offset(x: -6)
                Text(String(product.quantity))
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .offset(x: -13, y: 4)
            }
            .frame(width: 40)
            Divider()
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(product.estimatedShippingDate)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding()
        }
        .padding()
    }
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProductRow(product: modelInstance.orders[0].products[0])
        }
        .listStyle(InsetGroupedListStyle())
    }
}
