//
//  Settings.swift
//  Varakush
//
//  Created by Dmitrii Ziablikov on 02/06/2019.
//  Copyright © 2019 dimzfresh. All rights reserved.
//

import Foundation

public typealias AuthInfo = (token: String, name: String, email: String)

@propertyWrapper
struct UserDefaultSettings<T> {
    private let key: String
    private let value: T
    private let defaults: UserDefaults

    init(_ key: String, value: T, for defaults: UserDefaults = .standard) {
        self.key = key
        self.value = value
        self.defaults = defaults
    }

    var wrappedValue: T {
        get {
            return defaults.object(forKey: key) as? T ?? value
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}

final class Settings {
    private static let uathKey = "auth"
    private static let isShownOnboardingKey = "isShownOnboarding"
    private static let isAuthorizedKey = "isAuthorized"
    private static let tokenKey = "tokenKey"

    static let storage: Settings = Settings()
    
    private init() {}
    
    @UserDefaultSettings(isAuthorizedKey, value: false)
    var isAuthorized: Bool
    
    @UserDefaultSettings(isShownOnboardingKey, value: false)
    var isShownOnboarding: Bool
    
    @UserDefaultSettings(uathKey, value: [String : String]())
       var auth: [String : String]
    
    func set(key: String, value: Any?) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func get<T>(key: String) -> T? {
        let value = UserDefaults.standard.value(forKey: key)
        return value as? T
    }
    
    func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func saveAuth(_ info: AuthInfo) {
        var storedAuth = auth
        storedAuth["email"] = info.email
        storedAuth["name"] = info.name
        //storedAuth["id"] = info.id
        
        auth = storedAuth
        
        isAuthorized = true
        
        KeychainManager.save(value: info.token, for: Settings.tokenKey)
    }
    
    func getAuth() -> AuthInfo? {
        let token = KeychainManager.load(for: Settings.tokenKey) ?? ""
        let email: String = auth["email"] ?? ""
        let name: String = auth["name"] ?? ""
        //let id: String = auth["id"] ?? ""
        return (token: token, name: name, email: email)
    }
    
    func removeAuth() {
        remove(key: Settings.uathKey)
        isAuthorized = false
        KeychainManager.remove(for: Settings.tokenKey)
    }
}
