//
//  AppDelegate.swift
//  BagTrack
//
//  Created by Robin Kipp on 14.09.17.
//  Copyright © 2017 Robin Kipp. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dataModel:DataModel!
    var manager:CLLocationManager!
    var center:UNUserNotificationCenter!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataModel = DataModel.sharedInstance
        manager = CLLocationManager()
        manager.delegate = self
        center = UNUserNotificationCenter.current()
        if let navController = window?.rootViewController as? UINavigationController {
            guard let viewController = navController.topViewController as? BagsTableViewController else {
                fatalError("Found an incorrect view controller, unable to inject LocationManager.")
            }
            viewController.manager = CLLocationManager()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        dataModel.saveToDisk()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        showPermissionAlerts()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func showPermissionAlerts() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            if let navController = window?.rootViewController as? UINavigationController {
                guard let viewController = navController.topViewController as? BagsTableViewController else {
                    return
                }
                viewController.present(Helpers.showAlert(.noLocationPermission, error: nil), animated: true, completion: nil)
            }
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if !granted {
                DispatchQueue.main.async {
                    if let navController = self.window?.rootViewController as? UINavigationController {
                        guard let viewController = navController.topViewController as? BagsTableViewController else {
                            return
                        }
                        viewController.present(Helpers.showAlert(.noPushPermission, error: nil), animated: true, completion: nil)
                    }
                }
            }}
    }

}

// MARK: - CLLocationManagerDelegate

extension AppDelegate:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let region = region as? CLBeaconRegion else {
            return
        }
        for bag in dataModel.bags {
            if bag == region {
                let content = UNMutableNotificationContent()
                content.title = "BagTrack"
                content.body = NSLocalizedString("Oops, you might be about to loose \(bag.name)!", comment: "Shown as a push notification.")
                content.sound = UNNotificationSound(named: "Alarm.wav")
                let request = UNNotificationRequest(identifier: "BagTrack", content: content, trigger: nil)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}
