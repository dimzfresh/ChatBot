//
//  LoginModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

public struct LoginModel: Codable {
    var name: String?
    var activeShift: Shift?
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case name = "userName"
        case activeShift, token
    }
    
    init?(data: Data) {
        do {
            self = try JSONDecoder().decode(LoginModel.self, from: data)
        } catch(let error) {
            print(error)
            return nil
        }
    }
}
   
struct Shift: Codable {
    let guid: String? //w6+bqBlIRFW_FIPo9mQiLw
    let salespoint: String? //n+TXGoCoQ1KIjSD6lAhydw
    let started: String? //"2019-10-06T17:37:36Z\"
    
    enum CodingKeys: String, CodingKey {
        case started = "started_at"
        case guid, salespoint
    }
}

//extension LoginModel: Decodable {
//  public init(from decoder: Decoder) throws {
//    let values = try json.nestedContainer(keyedBy: CodingKeys.self, forKey: .json)
//    name = try values.decode(String.self, forKey: .name)
//    activeShift = try values.decode(Shift.self, forKey: .activeShift)
//    token = try values.decode(String.self, forKey: .token)
//  }
//}
