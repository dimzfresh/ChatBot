//
//  LoginViewController.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire

final class LoginViewController: UIViewController, BindableType {
    
    @IBOutlet weak private var emailTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var enterButton: UIButton!
    @IBOutlet weak private var showPasswordButton: UIButton!
    
    var viewModel: LoginViewModel!
    
    private let disposeBag = DisposeBag()
    
    private var showPassword: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

extension LoginViewController: AlamofireManager {
    func setup() {
        setTitleView()
        bind()
        keyboard()
    }
    
    // MARK: BindableType

    func bindViewModel() {
         bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
        emailTextField.rx.text
            .orEmpty
            .bind(to: viewModel.email)
            .disposed(by: disposeBag)

        passwordTextField.rx.text
            .orEmpty
            .bind(to: viewModel.password)
            .disposed(by: disposeBag)
        
        let email = emailTextField.rx.text.orEmpty.asObservable()
        let password = passwordTextField.rx.text.orEmpty.asObservable()
        
        viewModel.enterButtonValid(email: email, password: password)
            .bind(to: enterButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        
        // MARK: - Actions
        enterButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.viewModel?.request()
        }).disposed(by: disposeBag)
        
        showPasswordButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.show()
        }).disposed(by: disposeBag)
    }
    
    private func keyboard() {
        view.setDismissKeyboardOnTap()
    }
    
    private func show() {
        showPassword = !showPassword
        let image: UIImage = showPassword ? #imageLiteral(resourceName: "login_eye_open") : #imageLiteral(resourceName: "login_eye_open")
        showPasswordButton.setImage(image, for: .normal)
        passwordTextField.isSecureTextEntry = !showPassword
    }
}
