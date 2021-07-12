//
//  OrderRegistrarResult.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct OrderRegistrarResult: View {
    
    var orderID: String
    var placedDate: String?
    var completionDate: String?
    
    @Binding var progress: ProgressState
    @Binding var retrievalResult: RetrievalProcessResult
    
    var body: some View {
        Group {
            if progress == .retrieving {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if progress == .responded {
                HStack {
                    Group {
                        if retrievalResult == .none {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(.red)
                        }
                    }
                    .frame(width: 25, height: 25)
                    .padding([.top, .trailing, .bottom])
                    
                    Divider()
                    
                    if retrievalResult == .none {
                        VStack(alignment: .leading) {
                            Text("Order #\(orderID)")
                                .font(.headline)
                            
                            if let placedDate = placedDate {
                                Text(placedDate)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            if let completionDate = completionDate {
                                Text(completionDate)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else if retrievalResult == .alreadyExists {
                        VStack(alignment: .leading) {
                            Text("Already Exists in List")
                                .font(.headline)
                            
                            Text("The order information is already existed.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        VStack(alignment: .leading) {
                            Text("No Order Status")
                                .font(.headline)
                            
                            Text("Please check your Order ID and Email.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
            } else {
                EmptyView()
            }
        }
        .frame(height: 100)
    }
}

struct OrderRegistrarResult_Previews: PreviewProvider {
    
    static var previews: some View {
        List {
            OrderRegistrarResult(orderID: "00000", progress: .constant(.retrieving), retrievalResult: .constant(.none))
        }
        .listStyle(InsetGroupedListStyle())
        .frame(width: 400, height: 110, alignment: .center)
    }
}
