//
//  NSCoder + NSCoderKeys.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/07.
//

import Foundation

enum NSCodingKeys: String {
    case id = "ID"
    case name = "Name"
    case quantity = "Quantity"
    case manufacturedQuantity = "ManufacturedQuantity"
    case shippedQuantity = "ShippedQuantity"
    case estimatedShippingDate = "EstimatedShippingDate"
    case state = "State"
    case orderID = "OrderID"
    case email = "Email"
    case placedDate = "PlacedDate"
    case completionDate = "CompletionDate"
    case products = "Products"
    case orders = "Orders"
    case sortingOption = "SortingOption"
    case sortAscending = "SortAscending"
}

extension NSCoder {
    
    // MARK: - Encode
    
    func encode(_ object: Any?, forKey key: NSCodingKeys) {
        encode(object, forKey: key.rawValue)
    }
    
    func encodeConditionalObject(_ object: Any?, forKey key: NSCodingKeys) {
        encodeConditionalObject(object, forKey: key.rawValue)
    }
    
    func encode(_ value: Bool, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    func encodeCInt(_ value: Int32, forKey key: NSCodingKeys) {
        encodeCInt(value, forKey: key.rawValue)
    }
    
    func encode(_ value: Int32, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    func encode(_ value: Int64, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    func encode(_ value: Float, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    func encode(_ value: Double, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    func encodeBytes(_ bytes: UnsafePointer<UInt8>?, length: Int, forKey key: NSCodingKeys) {
        encodeBytes(bytes, length: length, forKey: key.rawValue)
    }
    
    func encode(_ value: Int, forKey key: NSCodingKeys) {
        encode(value, forKey: key.rawValue)
    }
    
    // MARK: - Decode
    
    func decodeObject(forKey key: NSCodingKeys) -> Any? {
        return decodeObject(forKey: key.rawValue)
    }

    func decodeBool(forKey key: NSCodingKeys) -> Bool {
        return decodeBool(forKey: key.rawValue)
    }

    func decodeCInt(forKey key: NSCodingKeys) -> Int32 {
        return decodeCInt(forKey: key.rawValue)
    }

    func decodeInt32(forKey key: NSCodingKeys) -> Int32 {
        return decodeInt32(forKey: key.rawValue)
    }

    func decodeInt64(forKey key: NSCodingKeys) -> Int64 {
        return decodeInt64(forKey: key.rawValue)
    }

    func decodeFloat(forKey key: NSCodingKeys) -> Float {
        return decodeFloat(forKey: key.rawValue)
    }

    func decodeDouble(forKey key: NSCodingKeys) -> Double {
        return decodeDouble(forKey: key.rawValue)
    }

    func decodeBytes(forKey key: NSCodingKeys, returnedLength lengthp: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? {
        return decodeBytes(forKey: key.rawValue, returnedLength: lengthp)
    }
    
    func decodeInteger(forKey key: NSCodingKeys) -> Int {
        return decodeInteger(forKey: key.rawValue)
    }

}
