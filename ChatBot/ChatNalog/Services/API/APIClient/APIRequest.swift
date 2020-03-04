//
//  Request.swift
//  ChatBot
//
//  Created by iOS dev on 13/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation
import Alamofire

public typealias Resource = (method: HTTPMethod, route: String)

public protocol APIRequest: AlamofireManager {
            
    var route: String { get set }
      
    var encoding: Alamofire.ParameterEncoding { get }
    
    var method: Alamofire.HTTPMethod { get }
    
    var parameters: [String : Any]? { get }
    
    var parametersData: Data? { get }
     
    var data: Data? { get }
  
    var headers: HTTPHeaders { get }
    
    var networkClient: APIClientProtocol { get }
    
}

extension APIRequest {

    var url: String { Server.base.description + route }
    
    var method: Alamofire.HTTPMethod { .get }

    public var encoding: Alamofire.ParameterEncoding { method == .get ? URLEncoding.queryString : JSONEncoding.default }
    
    public var parameters: [String : Any]? { nil }
    
    public var data: Data? { nil }
    
    public var parametersData: Data? {
        if let p = parameters {
            return try? JSONSerialization.data(withJSONObject: p, options: .prettyPrinted) as Data
        } else {
            return nil
        }
    }
 
    public var headers: HTTPHeaders { defaultHeaders }
       
    public var networkClient: APIClientProtocol { APIClient() }
}
