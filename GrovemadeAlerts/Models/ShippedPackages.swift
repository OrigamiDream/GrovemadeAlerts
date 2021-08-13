//
//  ShippedPackages.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/08/13.
//

import SwiftUI

class ShippedPackages: ObservableObject, Equatable {
    
    @Published var trackingNumber: String
    @Published var status: String
    @Published var estimatedDelivery: String
    @Published var location: String
    
    init(trackingNumber: String, status: String, estimatedDelivery: String, location: String) {
        self.trackingNumber = trackingNumber
        self.status = status
        self.estimatedDelivery = estimatedDelivery
        self.location = location
    }
    
    static func == (lhs: ShippedPackages, rhs: ShippedPackages) -> Bool {
        return lhs.trackingNumber == rhs.trackingNumber && lhs.status == rhs.status && lhs.estimatedDelivery == rhs.estimatedDelivery && lhs.location == rhs.location
    }
    
}

extension ShippedPackages: CodableExportable {
    
    var toCodable: CodableShippedPackages {
        CodableShippedPackages(trackingNumber: trackingNumber, status: status, estimatedDelivery: estimatedDelivery, location: location)
    }
    
}
