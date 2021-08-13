//
//  GrovemadeFetcher.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI
import Combine
import SwiftSoup

enum GrovemadeRetrivalError: Error {
    case noResponse
    case invalidStatusCode
    case noOrderStatus
    case invalidOrderStatus
    case invalidQuantities
    case invalidTrackingNumber
    case parserFailure(type: ExceptionType, message: String)
}

struct GrovemadeResponse {
    let placedDate: String
    let completionDate: String?
    let products: [Product]
    
    let trackingNumber: String?
    let deliveryStatus: String?
    let estimatedDelivery: String?
    let deliveryLocation: String?
}

func retrieveOrderInformationFromGrovemade<S>(queue: DispatchQueue, subject: S, orderID: String, email: String) where S: Subject, S.Failure == Error, S.Output == GrovemadeResponse {
    var retrivalDone: AnyCancellable?
    let group = DispatchGroup()
    
    queue.async {
        var responseString: String?
        
        group.enter()
        retrivalDone = sendRequestToGrovemade(orderID: orderID, email: email)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let failure):
                    subject.send(completion: .failure(failure))
                case .finished:
                    break
                }
                group.leave()
            }, receiveValue: { data, response in
                guard let response = response as? HTTPURLResponse else {
                    subject.send(completion: .failure(GrovemadeRetrivalError.noResponse))
                    return
                }
                guard response.statusCode == 200 else {
                    subject.send(completion: .failure(GrovemadeRetrivalError.invalidStatusCode))
                    return
                }
                responseString = String(data: data, encoding: .utf8)
            })
        group.wait()
        
        assert(retrivalDone != nil)
        guard let responseString = responseString else {
            subject.send(completion: .failure(GrovemadeRetrivalError.noResponse))
            return
        }
        
        parseGrovemadeResponseIntoComponents(subject: subject, responseString: responseString)
    }
}

fileprivate func sendRequestToGrovemade(orderID: String, email: String) -> URLSession.DataTaskPublisher {
    let session = URLSession.shared
    let params: [String: String] = [
        "order_number": orderID,
        "email": email
    ]
    let queryString = params
        .map { (key, value) in "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")
    var request = URLRequest(url: URL(string: "https://grovemade.com/support/order-status")!)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    request.httpBody = queryString.data(using: .utf8)
    return session.dataTaskPublisher(for: request)
}

fileprivate func parseGrovemadeResponseIntoComponents<S>(subject: S, responseString: String) where S: Subject, S.Failure == Error, S.Output == GrovemadeResponse {
    do {
        let document = try SwiftSoup.parse(responseString)
        let elements = try document.select(".row .g12 .order-status-result")
        guard elements.count > 0 else {
            subject.send(completion: .failure(GrovemadeRetrivalError.noOrderStatus))
            return
        }
        let placedDate = try elements.select("h1 + p").first()?.text() ?? ""
        let completionDate = try elements.select("h1 + p + hr + p").first()?.text()
        
        let orderTables = try document.select(".order-status-result table.table.table-hover.table-striped.table-condensed")
        guard let orderedItems = orderTables.first() else {
            subject.send(completion: .failure(GrovemadeRetrivalError.noOrderStatus))
            return
        }
        let rows = try orderedItems.select("tbody .product-table-row")
        var products: [Product] = []
        for row in rows {
            let children = row.children().map { try! $0.text().trimmingCharacters(in: .whitespacesAndNewlines) }
            guard children.count >= 5 else {
                subject.send(completion: .failure(GrovemadeRetrivalError.invalidOrderStatus))
                return
            }
            let product = children[0]
            let estimatedShippingDate = children[1]
            let quantityString = children[2]
            let quantityReadyString = children[3]
            let shippedString = children[4]
            
            guard let quantity = UInt(quantityString),
                  let quantityReady = UInt(quantityReadyString),
                  let shipped = UInt(shippedString) else {
                subject.send(completion: .failure(GrovemadeRetrivalError.invalidQuantities))
                return
            }
            
            let state: ProductState
            if quantity > 0 && quantityReady == 0 && shipped == 0 {
                state = .ordered
            } else if quantityReady > 0 && shipped == 0 {
                state = .manufactured
            } else if shipped > 0 {
                state = .shipped
            } else {
                state = .ordered
            }
            
            products += [Product(id: UUID(), name: product, quantity: quantity, manufacturedQuantity: quantityReady, shippedQuantity: shipped, estimatedShippingDate: estimatedShippingDate, state: state)]
        }
        var trackingNumber: String? = nil
        var deliveryStatus: String? = nil
        var estimatedDelivery: String? = nil
        var deliveryLocation: String? = nil
        
        if orderTables.count > 1, let shippedPackages = orderTables.last() {
            let columns = try shippedPackages.select("tbody tr td")
            guard let trackingNumberElement = try columns[1].select("a[href]").first() else {
                subject.send(completion: .failure(GrovemadeRetrivalError.invalidTrackingNumber))
                return
            }
            trackingNumber = try trackingNumberElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let deliveryInfoElements = try columns[2].select("span")
            let statusEl = deliveryInfoElements[0]
            let estimatedDeliveryEl = deliveryInfoElements[1]
            let locationEl = deliveryInfoElements[2]
            
            deliveryStatus = try statusEl.text().trimmingCharacters(in: .whitespacesAndNewlines)
            estimatedDelivery = try estimatedDeliveryEl.text().trimmingCharacters(in: .whitespacesAndNewlines)
            deliveryLocation = try locationEl.text().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        subject.send(GrovemadeResponse(placedDate: placedDate, completionDate: completionDate, products: products, trackingNumber: trackingNumber, deliveryStatus: deliveryStatus, estimatedDelivery: estimatedDelivery, deliveryLocation: deliveryLocation))
        subject.send(completion: .finished)
    } catch Exception.Error(let type, let message) {
        subject.send(completion: .failure(GrovemadeRetrivalError.parserFailure(type: type, message: message)))
    } catch {
        subject.send(completion: .failure(error))
    }
}
