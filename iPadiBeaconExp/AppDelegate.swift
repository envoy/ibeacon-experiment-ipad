//
//  AppDelegate.swift
//  iPadiBeaconExp
//
//  Created by Fang-Pen Lin on 2/7/17.
//  Copyright © 2017 Envoy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var logUploadingQueue: DispatchQueue!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        logUploadingQueue = DispatchQueue(label: "log-uploading-queue.envoy.com", qos: .userInteractive)

        let osVersion = UIDevice.current.systemVersion
        let systemUpTime = ProcessInfo.processInfo.systemUptime
        log("app-launch", "app launched, os_version=\(osVersion), systemUpTime=\(systemUpTime), options=\(launchOptions ?? nil)")
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        log("app-will-resign-active", "app will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        log("app-did-enter-background", "app did enter background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        log("app-will-enter-foreground", "app will enter foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        log("app-did-become-active", "app did become active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        log("app-will-terminate", "app will terminate")
    }

}


extension AppDelegate {
    func log(_ event: String, _ message: String) {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            let msgData = defaults.data(forKey: "log_msg") ?? Data()
            var msgs = String(data: msgData, encoding: .utf8) ?? ""

            var dict = [String: String]()
            dict["id"] = UUID.init().uuidString
            dict["event"] = event
            dict["message"] = message
            dict["created_at"] = Date().iso8601

            let json = try! JSONSerialization.data(withJSONObject: dict, options: .init(rawValue: 0))
            let jsonString = String(data: json, encoding: .utf8)!
            print(jsonString)

            msgs.append(jsonString + "\n")
            defaults.set(msgs.data(using: .utf8), forKey: "log_msg")
            defaults.set(true, forKey: "log_msg_updated")
            defaults.synchronize()

            self.uploadLog()
        }
    }

    func uploadLog() {
        logUploadingQueue.async {
            let defaults = UserDefaults.standard
            guard let userID = defaults.value(forKey: "user_id") as? String else {
                print("User not signed up yet, skip log uploading")
                return
            }
            guard defaults.bool(forKey: "log_msg_updated") else {
                print("Log not updated, skip log uploading")
                return
            }
            guard
                let msgData = defaults.data(forKey: "log_msg"),
                msgData.count > 0
                else {
                    print("No message, skip log uploading")
                    return
            }

            var bodyData = "\(userID)\n".data(using: .utf8)
            bodyData?.append(msgData)

            var request = URLRequest(url: Utils.apiURL.appendingPathComponent("upload-log"))
            request.addValue("binary/octet-stream", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "PUT"
            request.httpBody = bodyData

            let completed = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
                defer {
                    completed.signal()
                }
                if let error = error {
                    print("Failed to upload logs, error=\(error)")
                    return
                }
                let lastID = String(data: data!, encoding: .utf8)!
                guard lastID.characters.count > 0 else {
                    print("No updates")
                    return
                }
                print("Uploaded logs with last_id=\(lastID)")
                DispatchQueue.main.async {
                    defaults.set(lastID, forKey: "last_log_sync_id")
                    defaults.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "info-update"), object: nil)
                }
                self.purgeLogs(lastID: lastID)
            }
            task.resume()
            completed.wait()
        }
    }

    func purgeLogs(lastID: String) {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            let msgData = defaults.data(forKey: "log_msg") ?? Data()
            let msgs = String(data: msgData, encoding: .utf8) ?? ""

            let lines = msgs.components(separatedBy: "\n")
                .filter { $0.characters.count > 0 }
            guard lines.count > 0 else {
                print("No log messages")
                return
            }

            var remainLines: [String] = []
            for line in lines.reversed() {
                let json = try! JSONSerialization.jsonObject(
                    with: line.data(using: .utf8)!,
                    options: .allowFragments
                    ) as! [String: String]
                if json["id"]! == lastID {
                    break
                }
                remainLines.insert(line, at: 0)
            }
            let newMsgs = remainLines.joined(separator: "\n")
            defaults.set(newMsgs.data(using: .utf8), forKey: "log_msg")
            defaults.synchronize()
            print("Purged logs, lastID=\(lastID), originalLogs=\(lines.count), remainLogs=\(remainLines.count)")
        }
    }
}
