//
//  Environment.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

public enum Server: String {
    case base = "https://develop.varakush.com/api/v1"
    
    var description: String {
        switch self {
        case .base:
            return rawValue
        }
    }
}
