//
//  String+Base64.swift
//  ChatBot
//
//  Created by iOS dev on 06/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import CommonCrypto

extension String {
    func fromBase64(encoding: String.Encoding = .utf8) -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: encoding)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
