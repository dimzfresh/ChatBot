//
//  VoiceModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 29/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import UIKit

public struct VoiceModel: RawValue {
    var someBaseEncodedString: Data

    var someString: String? {
       get {
          return String(data: someBaseEncodedString, encoding: .utf8)
       }
    }
}

//extension VoiceModel {
//    struct Result: Codable {
//        var text: String
//
//        enum CodingKeys: String, CodingKey {
//            case text
//        }
//
//        init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            self.text = try container.decodeBase64(forKey: .text, encoding: .utf8)
//        }
//    }
//}
//
//extension KeyedDecodingContainer {
//    func decodeBase64(forKey key: Key, encoding: String.Encoding) throws -> String {
//        guard let string = try self.decode(String.self, forKey: key).fromBase64(encoding: .utf8) else {
//            throw DecodingError.dataCorruptedError(forKey: key, in: self,
//                                                   debugDescription: "Not a valid Base-64 representing UTF-8")
//        }
//        return string
//    }
//
//    func decodeBase64(forKey key: Key, encoding: String.Encoding) throws -> [String] {
//        var arrContainer = try self.nestedUnkeyedContainer(forKey: key)
//        var strings: [String] = []
//        while !arrContainer.isAtEnd {
//            guard let string = try arrContainer.decode(String.self).fromBase64(encoding: .utf8) else {
//                throw DecodingError.dataCorruptedError(forKey: key, in: self,
//                                                       debugDescription: "Not a valid Base-64 representing UTF-8")
//            }
//            strings.append(string)
//        }
//        return strings
//    }
//}
