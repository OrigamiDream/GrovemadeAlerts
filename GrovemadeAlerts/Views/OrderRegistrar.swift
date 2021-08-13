//
//  OrderRegistrar.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI
import Combine
import SwiftSoup

enum RetrievalProcessResult {
    case none
    case invalid
    case errorOccurrance
    case unexpectedError
    case alreadyExists
}

enum ProgressState {
    case none
    case retrieving
    case responded
}

struct OrderRegistrar: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var model: Model
    
    @ObservedObject var orderID = NumbersOnly()
    @State var email = ""
    
    @State var retrievalDone: AnyCancellable?
    
    @State var progress = ProgressState.none
    @State var retrievalResult = RetrievalProcessResult.none
    
    @State var placedDate: String?
    @State var completionDate: String?
    @State var retrievedProducts: [Product] = []
    
    @State var dispatchQueue = DispatchQueue(label: "order-registrar-queue")
    
    @State var shippedPackages: ShippedPackages?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    OrderInfoField(
                        stringValue: $orderID.value,
                        title: "Order ID",
                        placeholder: "Enter the Order ID...",
                        keyboardType: .numbersAndPunctuation,
                        disabled: (progress == .retrieving || progress == .responded) && retrievalResult == .none,
                        onComplete: retrieveOrderInformation)
                    OrderInfoField(
                        stringValue: $email,
                        title: "Email",
                        placeholder: "Enter the Email...",
                        keyboardType: .emailAddress,
                        disabled: (progress == .retrieving || progress == .responded) && retrievalResult == .none,
                        onComplete: retrieveOrderInformation)
                }
                Section {
                    OrderRegistrarResult(orderID: orderID.value, placedDate: placedDate, completionDate: completionDate, progress: $progress, retrievalResult: $retrievalResult)
                }
                if progress == .responded && retrievalResult == .none {
                    Section(header: Text("Ordered Items")) {
                        ForEach(retrievedProducts) { product in
                            ProductRow(product: product)
                        }
                    }
                    if let shippedPackages = shippedPackages {
                        Section(header: Text("Shipped Packages")) {
                            ShippedPackageRow(shippedPackages: Binding.constant(shippedPackages))
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Add Order Info", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }, trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
                
                let state = OrderState.fromProducts(shippedPackages: shippedPackages, products: retrievedProducts, completionDate: completionDate)
                let order = Order(id: UUID(), orderID: orderID.value, email: email, state: state, placedDate: placedDate ?? "", completionDate: completionDate, shippedPackages: shippedPackages)
                order.products = [Product](retrievedProducts)
                
                withAnimation {
                    model.orders += [order]
                    model.objectWillChange.send()
                    model.save()
                }
            }) {
                if progress == .retrieving && retrievalResult != .none {
                    ProgressView()
                } else {
                    Text("Done")
                }
            }.disabled(progress != .responded || retrievalResult != .none))
        }
    }
    
    private func retrieveOrderInformation() {
        guard progress == .none || progress == .responded else {
            return
        }
        guard !orderID.value.isEmpty && !email.isEmpty else {
            progress = .none
            return
        }
        let duplicates = model.orders.filter { $0.email == email && $0.orderID == orderID.value }
        if duplicates.count > 0 {
            withAnimation {
                progress = .responded
                retrievalResult = .alreadyExists
            }
            return
        }
        withAnimation {
            progress = .retrieving
        }
        dispatchQueue.async {
            let queue = DispatchQueue(label: "grovemade-retrieval-queue")
            let group = DispatchGroup()
            group.enter()
            
            var placedDateString: String?
            var completionDateString: String?
            var shippingInfo: ShippedPackages?
            var products: [Product] = []
            let subject = PassthroughSubject<GrovemadeResponse, Error>()
            retrieveOrderInformationFromGrovemade(queue: queue, subject: subject, orderID: orderID.value, email: email)
            retrievalDone = subject.sink { completion in
                var result = RetrievalProcessResult.none
                defer {
                    withAnimation {
                        retrievalResult = result
                    }
                    group.leave()
                }
                switch completion {
                case .failure(let error):
                    switch error {
                    case let retrievalError as GrovemadeRetrivalError:
                        switch retrievalError {
                        case .noOrderStatus:
                            result = .invalid
                            break
                        default:
                            print("An error has occurred: \(retrievalResult)")
                            result = .errorOccurrance
                            break
                        }
                    default:
                        print("Unexpected error: \(error)")
                        result = .unexpectedError
                    }
                case .finished:
                    result = .none
                    break
                }
            } receiveValue: { response in
                placedDateString = response.placedDate
                completionDateString = response.completionDate
                products += response.products
                if let trackingNumber = response.trackingNumber,
                   let status = response.deliveryStatus,
                   let estimatedDelivery = response.estimatedDelivery,
                   let location = response.deliveryLocation {
                    
                    shippingInfo = ShippedPackages(trackingNumber: trackingNumber, status: status, estimatedDelivery: estimatedDelivery, location: location)
                }
            }
            group.wait()
            
            assert(retrievalDone != nil)
            if let placedDateString = placedDateString {
                withAnimation {
                    retrievedProducts = products
                    placedDate = placedDateString
                    completionDate = completionDateString
                    shippedPackages = shippingInfo
                }
                
                print("PlacedDate: \(placedDateString)")
                if let completionDateString = completionDateString {
                    print("CompletionDate: \(completionDateString)")
                }
                print("Products: \(products)")
            }
            DispatchQueue.main.async {
                withAnimation {
                    progress = .responded
                }
            }
        }
    }
}

struct OrderRegistrar_Previews: PreviewProvider {
    
    @ObservedObject static var model = modelInstance
    
    static var previews: some View {
        OrderRegistrar(model: model)
    }
}
