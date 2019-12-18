//
//  ChatModel.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

public struct ChatModel: Codable {
    var dialogID: Int?
    var text: String?
    var buttonsDescription: String?
    var buttons: [AnswerButton]?
    var buttonContent: String?
    var buttonType: Int?
    
    init() {}

    enum CodingKeys: String, CodingKey {
        case dialogID = "dialogId"
        case text, buttonsDescription, buttons
        case buttonContent, buttonType
    }
}

struct AnswerButton: Codable {
    let name: String?
    let type: Int?
    let content, description: String?
}
