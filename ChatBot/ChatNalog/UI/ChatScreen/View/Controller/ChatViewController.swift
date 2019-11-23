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
import RxDataSources

final class ChatViewController: UIViewController, BindableType {
    
    @IBOutlet private weak var tableView: UITableView!
    
    var viewModel: ChatViewModel!
    
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionOfChat>(configureCell: configureCell)
    private lazy var configureCell: RxTableViewSectionedReloadDataSource<SectionOfChat>.ConfigureCell = { [unowned self] (dataSource, tableView, indexPath, item) in
        
        let section = dataSource.sectionModels[indexPath.section]
        guard case let TableViewItem.message(message) = item else {
            return UITableViewCell()
        }
        
        switch section.model {
        case .outgoing:
            return self.configOutgoingCell(for: message, atIndex: indexPath)
        case .incoming:
            return self.configOutgoingCell(for: message, atIndex: indexPath)
        }
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addFirstMessage()
    }
    
}

extension ChatViewController: UITableViewDelegate {
    func configOutgoingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeue(OutgoingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        //cell.viewModel = student
        return cell
    }
    
    func configIncomingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeue(IncomingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        //cell.viewModel = student
        return cell
    }
}

extension ChatViewController {
    func setup() {
        setupTableView()
        bind()
        keyboard()
    }
    
    private func setupTableView() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.bounces = false
        tableView.tableFooterView = UIView(frame: .zero)
        
        tableView.register(OutgoingBubbleTableViewCell.self, forCellReuseIdentifier: OutgoingBubbleTableViewCell.identifier)
        tableView.register(IncomingBubbleTableViewCell.self, forCellReuseIdentifier: IncomingBubbleTableViewCell.identifier)
    }
    
    // MARK: BindableType
    
    func bindViewModel() {
        bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
                
        viewModel.messages
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
//        dataSource.titleForHeaderInSection = { dataSource, index in
//          return dataSource.sectionModels[index].header
//        }
//
//        dataSource.titleForFooterInSection = { dataSource, indexPath in
//          return dataSource.sectionModels[index].footer
//        }
//
//        dataSource.canEditRowAtIndexPath = { dataSource, indexPath in
//          return true
//        }
//
//        dataSource.canMoveRowAtIndexPath = { dataSource, indexPath in
//          return true
//        }
                        
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
        
    }
    
    private func addFirstMessage() {
        let firstMessage = ChatModel(dialogID: nil, text: "Добрый день, задайте вопрос!", buttonsDescription: nil, buttons: nil, buttonContent: nil, buttonType: nil)
        viewModel.messages.onNext([SectionOfChat(model: .incoming, items: [.message(info: firstMessage)])])
    }
    
    private func keyboard() {
        view.setDismissKeyboardOnTap()
    }
}
