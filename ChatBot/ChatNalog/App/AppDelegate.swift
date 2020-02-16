//
//  AppDelegate.swift
//  ChatBot
//
//  Created by iOS dev on 20/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import Messages
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var config = Config(bundle: .main, locale: .current)
    
    private lazy var services: [UIApplicationDelegate] = {
        return [AppDelegateSettings()]
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setup(launchOptions)
        startRootView()
                                
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                //self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        defer { completionHandler() }
//        print(response.actionIdentifier)
//
//        let state: UIApplication.State = UIApplication.shared.applicationState
//        if state == .active || state == .inactive {
//            guard let userInfo = response.notification.request.content.userInfo as? [String: Any] else { return }
//            let feedback = notification.getFeedback(for: userInfo)
//            showViolation(for: feedback)
//        }
//    }

//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//
//        let state: UIApplication.State = application.applicationState
//        if state == .inactive || state == .background {
//            guard let userInfo = userInfo as? [String: Any] else { return }
//            let feedback = notification.getFeedback(for: userInfo)
//            showViolation(for: feedback)
//        }
//        //completionHandler(.noData)
//    }
}

private extension AppDelegate {
    func startRootView() {
        let splash: SplashViewController = .instanceController(storyboard: .splash)
        let splashnvc = UINavigationController(rootViewController: splash)
        splashnvc.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = splashnvc
        window?.makeKeyAndVisible()
        
        let vc = ChatModule.build()
        let nvc = UINavigationController(rootViewController: vc)
        nvc.setNavigationBarHidden(true, animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.window?.rootViewController = nvc
        }
    }
    
    func setup(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Services
        services.forEach { _ = $0.application?(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions) }
        
        setupFirebase()
        registerNotifications()
        setupMessaging()
        setupVoicePermission()
    }
    
    func setupFirebase() {
        if config.environment == .dev {
            print("DEVELOPMENT")
            let filePath = Bundle.main.path(forResource: "GoogleService-DEV-Info", ofType: "plist")
            guard let path = filePath, let fileopts = FirebaseOptions(contentsOfFile: path)
                else { assert(false, "Couldn't load config file") }
            FirebaseApp.configure(options: fileopts)
        } else {
            print("PROD")
            let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
            guard let path = filePath, let fileopts = FirebaseOptions(contentsOfFile: path)
                else { assert(false, "Couldn't load config file") }
            FirebaseApp.configure(options: fileopts)
        }
    }
    
    func setupMessaging() {
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
    }
    
    func registerNotifications() {
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          UIApplication.shared.registerUserNotificationSettings(settings)
        }

        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func setupVoicePermission() {
        VoiceManager.shared.permission()
    }
}
