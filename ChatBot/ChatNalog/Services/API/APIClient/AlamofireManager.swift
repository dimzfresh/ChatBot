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
    
    private var salt: String {
        return "q1w9e2r8t3y7"
    }
    
    var defaultHeaders: HTTPHeaders {
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let uuidBase64 = uuid.toBase64()
        
        let hashStr = uuid + salt
        let data = hashStr.data(using: .utf8) ?? Data()
        let raw = hashStr.digest(input: data as NSData)
        let hash = raw.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

        var headers: HTTPHeaders = ["Accept": "application/vnd.varakush.v1+json",
                                    "Content-Type": "application/json",
                                    "X-Varakush-Identity": uuidBase64 + " " + hash,
                                    "User-Agent":  "Varakush-Cashier-iOS/\(Bundle.main.releaseVersionNumber)/ \(UIDevice.current.type)"]
        if !auth.token.isEmpty {
            headers["Authorization"] = "Bearer \(auth.token)"
        }
        return headers
    }
}
