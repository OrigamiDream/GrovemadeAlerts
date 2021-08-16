//
//  ContentView.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @Environment(\.scenePhase) var scenePhase
    
    @ObservedObject var model: Model
    
    @State var showRegistrar = false
    @State var dispatchQueue = DispatchQueue(label: "grovemade-refresh-queue")
    @State var isUpdating = false
    @State var lastBackgroundEntered = Date()
    @State var triggerUpdate = false
    
    var body: some View {
        NavigationView {
            Group {
                if model.orders.count > 0 {
                    List {
                        if model.sortingOption == .state {
                            SortedOrdersView(model: model, keyPath: \.state, stringValue: { $0.description })
                        } else if model.sortingOption == .email {
                            SortedOrdersView(model: model, keyPath: \.email, stringValue: { $0 })
                        } else {
                            Text("An error has occurred")
                                .font(.title.bold())
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    VStack {
                        Text("No Orders")
                            .font(.title.bold())
                        Text("Add Grovemade orders here")
                            .font(.footnote)
                    }
                }
            }
            .navigationBarTitle("Order Status")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(SortingOption.allCases, id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        if model.sortingOption == option {
                                            model.sortAscending.toggle()
                                        } else {
                                            model.sortingOption = option
                                            model.sortAscending = true
                                        }
                                        model.save()
                                    }
                                }
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    Spacer()
                                    if model.sortingOption == option {
                                        if model.sortAscending {
                                            Image(systemName: "chevron.up")
                                        } else {
                                            Image(systemName: "chevron.down")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showRegistrar = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if isUpdating {
                        VStack(spacing: 5) {
                            ProgressView()
                            Text("Getting new info from Grovemade")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRegistrar) {
            OrderRegistrar(model: model)
        }
        .onAppear {
            triggerUpdate = true
        }
        .onChange(of: triggerUpdate) { trigger in
            if trigger {
                print("Triggered refresh...")
                withAnimation {
                    isUpdating = true
                }
                print("Updating orders...")
                dispatchQueue.async {
                    let numRefreshed = model.refresh()
                    print("\(numRefreshed) orders have been refreshed.")
                    DispatchQueue.main.sync {
                        UIApplication.shared.applicationIconBadgeNumber = numRefreshed
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            isUpdating = false
                        }
                    }
                }
                triggerUpdate = false
            } else {
                print("Trigger has ended.")
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                let now = Date()
                let fifteenMinutes = TimeInterval(60 * 15) // 15 minutes
                guard now > (lastBackgroundEntered + fifteenMinutes) else {
                    return
                }
                triggerUpdate = true
                
            case .background:
                lastBackgroundEntered = Date()
                
            default:
                break
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    @ObservedObject static var model = modelInstance
    
    static var previews: some View {
        ContentView(model: model)
    }
}
