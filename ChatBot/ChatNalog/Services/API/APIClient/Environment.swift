//
//  Environment.swift
//  ChatBot
//
//  Created by iOS dev on 13/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

public enum Server: String {
    case base = "https://chatbotfnsapi.azurewebsites.net/api"
    
    var description: String {
        switch self {
        case .base:
            return rawValue
        }
    }
}
