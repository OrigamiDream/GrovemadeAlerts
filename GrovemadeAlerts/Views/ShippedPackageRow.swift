//
//  ShippedPackageRow.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/08/13.
//

import SwiftUI

struct ShippedPackageRow: View {
    
    @Binding var shippedPackages: ShippedPackages
    
    var body: some View {
        Group {
            HStack {
                Text("Tracking Number")
                Spacer()
                Button(shippedPackages.trackingNumber) {
                    if let url = URL(string: "https://www.ups.com/track?tracknum=\(shippedPackages.trackingNumber)") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            OrderInfoField(stringValue: $shippedPackages.status, title: "Status", placeholder: "Status", keyboardType: .default, disabled: true) {}
            OrderInfoField(stringValue: $shippedPackages.estimatedDelivery, title: "Estimated Delivery", placeholder: "Estimated Delivery", keyboardType: .default, disabled: true) {}
            OrderInfoField(stringValue: $shippedPackages.location, title: "Location", placeholder: "Location", keyboardType: .default, disabled: true) {}
        }
    }
}

struct ShippedPackageRow_Previews: PreviewProvider {
    
    @State static var shippedPackages = ShippedPackages(trackingNumber: "000000000000000000", status: "On the Way", estimatedDelivery: "Wed, August 18", location: "Incheon, KR")
    
    static var previews: some View {
        List {
            ShippedPackageRow(shippedPackages: $shippedPackages)
        }
        .listStyle(InsetGroupedListStyle())
    }
}
