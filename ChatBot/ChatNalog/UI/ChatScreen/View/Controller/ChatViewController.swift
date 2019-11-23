//
//  ViewController.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 20/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class ChatViewController: UIViewController, BindableType {
    
    @IBOutlet weak private var tableView: UITableView!
    
    var viewModel: ChatViewModel!
    
    private let disposeBag = DisposeBag()
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
}

extension ChatViewController {
    func setup() {
        bind()
        keyboard()
    }
    
    // MARK: BindableType
    
    func bindViewModel() {
        bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
                
//        viewModel.chat.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, model, cell in
//            cell.textLabel?.text = " "
//            cell.textLabel?.numberOfLines = 0
//            cell.selectionStyle = .none
//        }.disposed(by: disposeBag)
        
//        emailTextField.rx.text
//            .orEmpty
//            .bind(to: viewModel.question)
//            .disposed(by: disposeBag)
//
//        passwordTextField.rx.text
//            .orEmpty
//            .bind(to: viewModel.password)
//            .disposed(by: disposeBag)
//
//        let email = emailTextField.rx.text.orEmpty.asObservable()
//        let password = passwordTextField.rx.text.orEmpty.asObservable()
//
//        viewModel.enterButtonValid(email: email, password: password)
//            .bind(to: enterButton.rx.isEnabled)
//            .disposed(by: disposeBag)
        
        
        // MARK: - Actions
//        enterButton.rx.tap.subscribe(onNext: { [weak self] _ in
//            self?.viewModel?.request()
//        }).disposed(by: disposeBag)
//
//        showPasswordButton.rx.tap.subscribe(onNext: { [weak self] _ in
//            self?.show()
//        }).disposed(by: disposeBag)
    }
    
    private func keyboard() {
        view.setDismissKeyboardOnTap()
    }
}
