//
//  Bundle.swift
//  ChatBot
//
//  Created by iOS dev on 06/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "no version"
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "no version"
    }
}
