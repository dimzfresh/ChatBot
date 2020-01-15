//
//  AppDelegateSettings.swift
//  ChatBot
//
//  Created by iOS dev on 06/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import Firebase

final class AppDelegateSettings: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setup()
        
        return true
    }
}

private extension AppDelegateSettings {
    func setup() {
        setupNavigationBar()
        setupFirebase()
    }
    
    func setupNavigationBar() {
        let barAppearance = UINavigationBar.appearance()

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .brandColor
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            barAppearance.standardAppearance = appearance
            barAppearance.compactAppearance = appearance
            barAppearance.scrollEdgeAppearance = appearance
        } else {
            barAppearance.barTintColor = .brandColor
            barAppearance.isTranslucent = false
            if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
                statusBar.setValue(UIColor.white, forKey: "foregroundColor")
            }
        }
        barAppearance.tintColor = .white
        barAppearance.shadowImage = UIImage()
    }
    
    func setupFirebase() {
        FirebaseApp.configure()
    }
}
