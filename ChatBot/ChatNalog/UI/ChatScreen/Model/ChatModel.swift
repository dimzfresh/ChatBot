//
//  ChatModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

public struct ChatModel: Codable {
    let dialogID: Int?
    let text: String?
    let buttonsDescription: String?
    let buttons: [AnswerButton]?
    let buttonContent: String?
    let buttonType: Int?

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
