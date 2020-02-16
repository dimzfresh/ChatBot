//
//  Environment.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 16.02.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import Foundation

public protocol ConfigProvidingType: class {
    var config: ConfigType { get }
}

public protocol ConfigType {
    var environment: Environment? { get }
    var appVersion: String { get }
    var deviceModel: String { get }
    var os: String { get }
    var buildNumber: String { get }
    var apiVersion: String { get }
    //var baseUrl: URL? { get }
    var locale: Locale { get }
    init(bundle: Bundle, locale: Locale)
}

public enum Environment: String {
    case dev
    case qa
    case prod
}

public class Config: ConfigType {
    public let environment: Environment?
    public let os: String
    public let deviceModel: String
    public let appVersion: String
    public let buildNumber: String
    public let apiVersion: String
    public let locale: Locale
    
    // MARK: - Keys
    enum PlistKeys {
        static let baseURL = "Base URL"
        static let environment = "Environment"
        static let apiKey = "Api key"
    }
    
    // MARK: - Plist
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
    
    static let baseUrl: String = {
        guard let url = Config.infoDictionary[PlistKeys.baseURL] as? String else {
            fatalError("Root URL not set in plist for this environment")
        }
        return url
    }()
    
    public required init(bundle: Bundle, locale: Locale) {
        self.locale = locale
        
        //let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let appVersion = bundle.object(forInfoDictionaryKey: "AppleStoreVersion") as? String
        self.appVersion = appVersion ?? ""

        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        self.buildNumber = buildNumber ?? ""

        let apiVersion = bundle.object(forInfoDictionaryKey: "API Version") as? String
        self.apiVersion = apiVersion ?? ""
        
        let os = ProcessInfo().operatingSystemVersion
        self.os = String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
        
        //let model = UIDevice.current.
        self.deviceModel = "model"
        
        guard let env = bundle.object(forInfoDictionaryKey: PlistKeys.environment) as? String else {
            fatalError("ENVIRONMENT not set in plist")
        }
        self.environment = Environment(rawValue: env)
    
//        guard let rootURLstring = bundle.object(forInfoDictionaryKey: PlistKeys.baseURL) as? String else {
//            fatalError("Base URL not set in plist for this environment")
//        }
        
        //self.baseUrl = URL(string: rootURLstring)
    }
}
