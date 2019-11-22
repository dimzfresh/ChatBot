//
//  RequestsFactory.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Alamofire
import RxSwift

public final class RequestsFactory {
    enum User {
        case login(email: String, password: String)
        case logout
        //case getUser(String)

        public var request: APIRequest {
            switch self {
            case .login(let email, let password):
                return LoginRequest(email: email, password: password)
            case .logout:
                return LoginRequest(email: "email", password: "password")
            //case .getUser(let id):
                //return (.get, "/user/\(id)")
            }
        }
    }
}

public final class LoginRequest: APIRequest {
            
    public var resource: Resource { (method: .post, route: "/cashier/login") }
    public var method: HTTPMethod { resource.method }
    
    private let email: String
    private let password: String
    
    public var parameters: [String : Any]? {
        return ["email" : "testuser1@varakush.com", "password" : "qwerty123"]
    }
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
