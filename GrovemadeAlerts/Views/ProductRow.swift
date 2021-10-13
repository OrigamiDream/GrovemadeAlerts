//
//  ProductRow.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI

struct ProductImageRow: View {
    
    @GestureState var isLongPressing = false
    var url: URL?
    
    let size = CGSize(width: 75, height: 75)
    
    var body: some View {
        VStack {
            if let url = url,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
            } else {
                Spacer()
                    .frame(width: size.width)
                    .padding(5)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(url != nil ? .white : Color.white.opacity(0.0))
        .cornerRadius(Double(min(size.width, size.height)) * 0.225)
        .offset(x: -5)
    }
    
}

struct ProductRow: View {
    
    var product: Product
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ProductImageRow(url: product.image)
                Divider()
                HStack {
                    Text(String(product.quantity))
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
                    .offset(x: -10)
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .lineLimit(1)
                    
                    HStack(spacing: 0) {
                        Text("Status: ")
                        Text(product.state.description)
                            .foregroundColor(product.state == .inProduction ? .orange : .green)
                    }
                    .font(.footnote)
                }
            }
        }
    }
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProductRow(product: modelInstance.orders[0].products[0])
            ProductRow(product: modelInstance.orders[0].products[1])
        }
        .listStyle(InsetGroupedListStyle())
        .colorScheme(.dark)
    }
}
