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
    @IBOutlet private weak var inputTextView: UITextView!
    @IBOutlet private weak var sendButton: UIButton!
    
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
            return self.configIncomingCell(for: message, atIndex: indexPath)
        }
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.addFirstMessage()
    }
}

extension ChatViewController: UITableViewDelegate {
    func configOutgoingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeue(OutgoingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        cell.message = message
        return cell
    }
    
    func configIncomingCell(for message: ChatModel, atIndex: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeue(IncomingBubbleTableViewCell.self) else {
            return UITableViewCell()
        }
        cell.message = message
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ChatViewController {
    func setup() {
        keyboard()
    }
    
    private func setupTableView() {
        //tableView.delegate = nil
        //tableView.dataSource = nil
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        
        tableView.register(OutgoingBubbleTableViewCell.nib, forCellReuseIdentifier: OutgoingBubbleTableViewCell.identifier)
        tableView.register(IncomingBubbleTableViewCell.nib, forCellReuseIdentifier: IncomingBubbleTableViewCell.identifier)
    }
    
    // MARK: BindableType
    
    func bindViewModel() {
        setupTableView()
        bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
                
        viewModel.messages
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        inputTextView.rx.text
            .orEmpty
            .bind(to: viewModel.question)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            //.debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.addMessage()
                self?.viewModel.request()
            })
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


//        let email = emailTextField.rx.text.orEmpty.asObservable()
//        let password = passwordTextField.rx.text.orEmpty.asObservable()
//
//        viewModel.enterButtonValid(email: email, password: password)
//            .bind(to: enterButton.rx.isEnabled)
//            .disposed(by: disposeBag)
    }
    
    private func keyboard() {
        view.setDismissKeyboardOnTap()
    }
}
