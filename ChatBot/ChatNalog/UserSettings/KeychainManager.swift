//
//  KeychainService.swift
//  Markirovka
//
//  Created by Dmitrii Ziablikov on 11/04/2019.
//  Copyright © 2019 Dmitrii Ziablikov. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

final class KeychainManager {
    private static let uniqueServiceName = "markirovkaService"
    private static let uniqueAccessGroup = "tokensGroup"
    private static let instance = KeychainWrapper(serviceName: uniqueServiceName, accessGroup: uniqueAccessGroup)
    
    private init() {}
    
    class func save(value: String, for key: String) {
        let _: Bool = instance.set(value, forKey: key)
    }
    
    class func remove(for key: String) {
        let _: Bool = instance.removeObject(forKey: key)
    }
    
    class func load(for key: String) -> String? {
        let value: String? = instance.string(forKey: key)
        return value
    }
}
