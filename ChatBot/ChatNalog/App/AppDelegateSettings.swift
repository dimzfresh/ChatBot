//
//  AppDelegateSettings.swift
//  ChatBot
//
//  Created by iOS dev on 06/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class AppDelegateSettings: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setup()
        
        return true
    }
}

private extension AppDelegateSettings {
    func setup() {
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .brandColor
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = .brandColor
            UINavigationBar.appearance().isTranslucent = false
            if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
                statusBar.setValue(UIColor.white, forKey: "foregroundColor")
            }
        }
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().shadowImage = UIImage()
    }
}
