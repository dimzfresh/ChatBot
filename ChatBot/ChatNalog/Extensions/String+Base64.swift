//
//  String+Base64.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import CommonCrypto

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
