//
//  CoreData+Messages.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 20/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import CoreData

extension Messages: ManagedObjectProtocol {
    func toEntity() -> ChatModel? {
        var message = ChatModel()
        message.dialogID = Int(dialogID)
        message.buttonContent = buttonContent
        message.buttonsDescription = buttonDescription
        message.buttonType = Int(buttonType)
        message.text = text
        message.isIncoming = isIncoming
        message.identifier = identifier ?? UUID().uuidString
        message.date = date
        let data = (buttons ?? "").data(using: .utf8) ?? Data()
        message.buttons = Buttons(data: data)?.buttons
        return message
    }
}
