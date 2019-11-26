//
//  AlamofireManager.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Alamofire

public protocol AlamofireManager {
    var manager: SessionManager { get }
}

extension AlamofireManager {
    public var manager: SessionManager {
        let manager = Alamofire.SessionManager.default
        //manager.session.configuration.httpShouldSetCookies = true
        manager.session.configuration.timeoutIntervalForRequest = 15
        return manager
    }
    
    var auth: AuthInfo {
        guard let auth = Settings.storage.getAuth() else { return (token: "", name: "", email: "") }
        return auth
    }
    
    var defaultHeaders: HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json",
                                    "User-Agent":  "ChatNalog-iOS/\(Bundle.main.releaseVersionNumber)/ \(UIDevice.current.type)"]
        if !auth.token.isEmpty {
            headers["Authorization"] = "Bearer \(auth.token)"
        }
        return headers
    }
}
