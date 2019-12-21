//
//  ChatModel.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation
import CoreData

public struct ChatModel: Codable {
    var dialogID: Int?
    var text: String?
    var buttonsDescription: String?
    var buttons: [AnswerButton]?
    var buttonContent: String?
    var buttonType: Int?
    var isIncoming: Bool?
    var identifier: String = UUID().uuidString
    var date: Date? = Date()

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

struct Buttons: Codable {
    let buttons: [AnswerButton]?
    
    init?(data: Data) {
        do {
            self.buttons = try JSONDecoder().decode([AnswerButton].self, from: data)
        } catch (let error) {
            print(error.localizedDescription)
            return nil
        }
    }
}


extension ChatModel {
    func toJSON() -> String? {
        do {
            let jsonData = try JSONEncoder().encode(buttons)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch let error {
            print("error converting to json: \(error)")
            return nil
        }
    }
}

extension ChatModel: ManagedObjectConvertible {
    func toManagedObject(in context: NSManagedObjectContext) -> Messages? {
        let message = Messages.getOrCreateSingle(with: identifier, from: context)
        message.dialogID = Int64(dialogID ?? 0)
        message.identifier = identifier
        message.text = text
        message.isIncoming = isIncoming ?? false
        message.buttonDescription = buttonsDescription
        message.buttonContent = buttonContent
        message.buttons = toJSON()
        message.buttonType = Int64(buttonType ?? 0)
        message.date = date

        return message
    }
}
