//
//  ChatModule.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import Foundation

final class ChatModule {
    static func build() -> ChatViewController {
        let viewController: ChatViewController = .instanceController(storyboard: .chat)
        let viewModel = ChatViewModel(service: ChatService())
        viewController.bind(to: viewModel)
        
        return viewController
    }
}
