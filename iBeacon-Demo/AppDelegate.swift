//
//  AppDelegate.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/13/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
//    var broadcastBlock: DispatchWorkItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
//    func setupBroadcastBlock() {
//        broadcastBlock = DispatchWorkItem { [weak self] in
//            guard let self = self else { return }
//
//            let number = Int.random(in: 0...1000000)
//            let textToBroadcast = "\(number)"
//            self.log("Broadcast value: \(textToBroadcast)")
//            self.peripheralManager.updateValue(Data(textToBroadcast.utf8), for: self.mutableCharacteristic, onSubscribedCentrals: self.subscribers)
//            self.broadcast()
//        }
//    }
//
//    func broadcast() {
//        let delay: Double = 2
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
//                                      execute: broadcastBlock!)
//    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        BluetoothManager.shared.delegate = self
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: BluetoothManagerDelegate {
    func bluetoothManager(_ bluetoothManager: BluetoothManager, log text: String) {
        CentralData.shared.logs.append(text)
    }
    
    func bluetoothManagerDidUpdatePeripheral(_ bluetoothManager: BluetoothManager) {
        
    }
}

