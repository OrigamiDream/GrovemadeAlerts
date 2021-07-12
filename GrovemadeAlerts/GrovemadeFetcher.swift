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
    case parserFailure(type: ExceptionType, message: String)
}

struct GrovemadeResponse {
    let placedDate: String
    let completionDate: String?
    let products: [Product]
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
        
        guard let table = try document.select(".order-status-result table.table.table-hover.table-striped.table-condensed").first() else {
            subject.send(completion: .failure(GrovemadeRetrivalError.noOrderStatus))
            return
        }
        let rows = try table.select("tbody .product-table-row")
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
        subject.send(GrovemadeResponse(placedDate: placedDate, completionDate: completionDate, products: products))
        subject.send(completion: .finished)
    } catch Exception.Error(let type, let message) {
        subject.send(completion: .failure(GrovemadeRetrivalError.parserFailure(type: type, message: message)))
    } catch {
        subject.send(completion: .failure(error))
    }
}
