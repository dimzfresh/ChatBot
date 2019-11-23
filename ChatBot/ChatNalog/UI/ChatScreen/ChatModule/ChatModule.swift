//
//  ChatModule.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
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
