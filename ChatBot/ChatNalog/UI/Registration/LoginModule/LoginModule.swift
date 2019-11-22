//
//  LoginModule.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation

final class LoginModule {
    static func build() -> LoginViewController {
        let viewController: LoginViewController = .instanceController(storyboard: .login)
        let viewModel = LoginViewModel(service: UserService())
        viewController.bind(to: viewModel)
        
        return viewController
    }
}
