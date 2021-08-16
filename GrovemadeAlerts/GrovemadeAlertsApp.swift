//
//  GrovemadeAlertsApp.swift
//  GrovemadeAlerts
//
//  Created by Avis Studio on 2021/07/06.
//

import SwiftUI
import BackgroundTasks
import Combine
import UserNotifications

let grovemadeModelKey = "GrovemadeModelKey"

@main
struct GrovemadeAlertsApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    let notificationDelegate = NotificationDelegate()
    let dispatchQueue = DispatchQueue(label: "retrieval-background-task-queue")
    let model: Model
    
    init() {
        let defaults = UserDefaults.standard

        if let encoded = defaults.data(forKey: grovemadeModelKey) {
            model = try! JSONDecoder().decode(CodableModel.self, from: encoded).toElement
        } else {
            model = Model()
        }

        UNUserNotificationCenter.current().delegate = notificationDelegate
        print("Registering scheduled background tasks...")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskKeys.refresh.rawValue, using: dispatchQueue, launchHandler: refreshGrovemadeInformations)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                        if let error = error {
                            print("Unexpected error while granting notification authorization: \(error)")
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                print("Application is entering into background mode...")
                scheduleNextRefresh()
            default:
                break
            }
        }
    }
    
    func scheduleNextRefresh() {
        print("Scheduling Grovemade orders info refresh...")
        let taskRequest = BGAppRefreshTaskRequest(identifier: BackgroundTaskKeys.refresh.rawValue)
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 5) // 10 minutes later from now
        dispatchQueue.async {
            do {
                try BGTaskScheduler.shared.submit(taskRequest)
                print("Submitted next refresh schedule")
            } catch {
                print("Could not schedule next refresh caused by: \(error)")
            }
        }
    }
    
    func refreshGrovemadeInformations(task: BGTask) {
        guard let task = task as? BGAppRefreshTask else {
            return
        }
        scheduleNextRefresh()
        
        print("Refreshing app...")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        task.expirationHandler = {
            queue.cancelAllOperations()
            print("Task has been expired. Cancelled all operation")
        }
        queue.addOperation {
            let numRefreshed = model.refresh()
            print("\(numRefreshed) orders have been refreshed in background.")
            if numRefreshed > 0 {
                DispatchQueue.main.sync {
                    UIApplication.shared.applicationIconBadgeNumber = numRefreshed
                }
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    switch settings.authorizationStatus {
                    case .authorized, .provisional:
                        // Create LocalNotification to notify.
                        let notification = UNMutableNotificationContent()
                        let verbs: String
                        if numRefreshed <= 1 {
                            verbs = "is an"
                        } else {
                            verbs = "are some"
                        }
                        notification.title = "There \(verbs) updated Grovemade orders!"
                        notification.body = "\(numRefreshed) orders have been updated."
                        notification.sound = .default
                        
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
                        UNUserNotificationCenter.current().add(request) { error in
                            guard error == nil else {
                                return
                            }
                            print("Notification have been requested: \(request.identifier)")
                        }
                    default:
                        break
                    }
                }
            }
            task.setTaskCompleted(success: true)
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .list])
    }
    
}
