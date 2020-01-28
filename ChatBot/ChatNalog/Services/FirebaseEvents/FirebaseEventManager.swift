//
//  FirebaseEventManager.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 28.01.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import Foundation
import FirebaseAnalytics

final class FirebaseEventManager {
    static let shared = FirebaseEventManager()
    private init() {}
}

extension FirebaseEventManager {
    func logEvent(input: EventInput) {
        
        switch input.event {
        case .chat(let event):
            log(name: event.identifier,
                parameters: ["target" : event.name,
                             "name" : event.rawValue])
        case .share(let event):
            log(name: event.identifier,
                parameters: ["target" : event.name,
                             "name" : event.rawValue])
        case .voice(let event):
            log(name: event.identifier,
                parameters: ["target" : event.name,
                             "name" : event.rawValue])
        }
    }
    
    private func log(name: String, parameters: [String:Any]) {
        DispatchQueue.global(qos: .utility).async {
            Analytics.logEvent(name, parameters: parameters)
        }
    }
}
