//
//  OrderRow.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct OrderRow: View {
    
    @ObservedObject var order: Order
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(order.orderID)
                    .font(.title.monospacedDigit())
                    .padding([.bottom], 5)
                
                if order.isUpdated {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 7, height: 7, alignment: .center)
                        Spacer()
                    }
                }
                
                // replacement package
                if order.orderID.starts(with: "-") {
                    Text("(replacement package)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .textCase(.lowercase)
                }
            }
            Text(order.textDescription)
                .font(.footnote)
                .foregroundColor(.gray)
                .textCase(.none)
        }
        .padding(5)
    }
    
}
