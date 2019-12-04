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
