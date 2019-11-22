//
//  Storyboards.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit

public enum Storyboards: String {
    case splash = "LaunchScreen"
    case login = "Login"
    case main = "Main"
    
    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
    
//    static func getFlow() -> Storyboards {
//        switch (Session.isShownOnboarding, Session.isAuthorized, Session.isShownProfile) {
//        case (true, false, _):
//            return .start
//        case (false, false, false), (false, true, false):
//            return .onboarding
//        //case (true, true, false):
//            //return .profile
//        case (true, true, _):
//            return .main
//        default:
//            return .main
//        }
//    }
}
