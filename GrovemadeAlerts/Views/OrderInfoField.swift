//
//  OrderInfoField.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct OrderInfoField: View {
    
    @Binding var stringValue: String
    
    var title: LocalizedStringKey
    var placeholder: LocalizedStringKey
    var keyboardType: UIKeyboardType
    var disabled: Bool
    var onComplete: () -> ()
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: $stringValue) { isEditing in
                if !isEditing {
                    onComplete()
                }
            } onCommit: {
                onComplete()
            }
            .frame(minWidth: 100)
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
            .keyboardType(keyboardType)
            .foregroundColor(.accentColor)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .disabled(disabled)
        }
    }
}

struct OrderInfoField_Previews: PreviewProvider {
    
    @State static var orderID = ""
    @State static var email = ""
    
    static var previews: some View {
        List {
            Section {
                OrderInfoField(stringValue: $orderID, title: "Order ID", placeholder: "Enter the Order ID...", keyboardType: .numbersAndPunctuation, disabled: false) {
                    print("On Complete: \(orderID)")
                }
                OrderInfoField(stringValue: $email, title: "Email", placeholder: "Enter the Email...", keyboardType: .emailAddress, disabled: false) {
                    print("On Complete: \(email)")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
