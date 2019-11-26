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

enum ScorllPosition {
    case top
    case middle(index: Int)
    case bottom
}

final class ChatViewController: UIViewController, BindableType {
    
    @IBOutlet private weak var titleButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var inputTextView: CustomInputView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var inputStackViewConstraint: NSLayoutConstraint!
    
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
    
    private var keyboardHeight: Observable<CGFloat> {
        return Observable
            .from([
                NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
                    .map { notification -> CGFloat in
                        return (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
                },
                NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
                    .map { _ -> CGFloat in
                        return 0
                }
            ])
            .merge()
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
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
        cell.selectedItem
            .subscribe(onNext: { [weak self] position in
                self?.viewModel.sendQuestion()
            }).disposed(by: disposeBag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
}

extension ChatViewController {
    private func setup() {
        setupTitle()
        keyboard()
    }
    
    private func setupTitle() {
        let partOne = NSAttributedString(string: "Налоговый помощник Жора",
                                         attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .semibold)])
        let partTwo = NSAttributedString(string: "\nОнлайн",
                                         attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular)])
        let buttonTitle = NSMutableAttributedString()
        buttonTitle.append(partOne)
        buttonTitle.append(partTwo)
        
        titleButton.titleLabel?.numberOfLines = 0
        titleButton.titleLabel?.lineBreakMode = .byWordWrapping
        titleButton.setAttributedTitle(buttonTitle, for: .normal)
        //("Налоговый помощник Жора\nОнлайн", for: .normal)
        titleButton.titleLabel?.textAlignment = .left
        titleButton.sizeToFit()
    }
        
    private func setupTableView() {
        //tableView.delegate = nil
        //tableView.dataSource = nil
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.keyboardDismissMode = .interactive
        
        tableView.register(OutgoingBubbleTableViewCell.nib, forCellReuseIdentifier: OutgoingBubbleTableViewCell.identifier)
        tableView.register(IncomingBubbleTableViewCell.nib, forCellReuseIdentifier: IncomingBubbleTableViewCell.identifier)
    }
    
    // MARK: BindableType
    
    func bindViewModel() {
        setupTableView()
        viewModel.addFirstMessage()
        bind()
    }
    
    private func bind() {
        guard let viewModel = viewModel else { return }
                        
        viewModel.messages
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.scrollPosition
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] position in
                    self?.scrollToPosition(position: position)
               }).disposed(by: disposeBag)

        inputTextView.rx.text
            .orEmpty
            .do(onNext: { [weak self] text in
                guard let self = self else { return }
                self.sendButton.isEnabled = !text.isEmpty
                let image: UIImage = text.isEmpty ? #imageLiteral(resourceName: "send_button_empty") : #imageLiteral(resourceName: "send_button_ok")
                UIView.transition(with: self.sendButton, duration: 0.15, options: .transitionCrossDissolve, animations: {
                    self.sendButton.setImage(image, for: .normal)
                })
            })
            .bind(to: viewModel.questionInput)
            .disposed(by: disposeBag)
        
        viewModel.questionInput
            .asObservable()
            .bind { text in
                self.inputTextView.text = text
        }
        .disposed(by: disposeBag)
        
        sendButton.rx.tap
            //.debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.sendQuestion()
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
    }
    
    private func keyboard() {
        inputTextView.autocorrectionType = .no
        keyboardHeight
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { keyboardHeight in
                if keyboardHeight == 0 {
                    self.inputStackViewConstraint.constant = 24
                } else {
                    self.inputStackViewConstraint.constant = 24 + keyboardHeight
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
                self.scrollToPosition(position: .bottom)
            })
            .disposed(by: disposeBag)
    }
    
    private func scrollToPosition(position: ScorllPosition) {
        switch position {
        case .top:
            let indexPath = IndexPath.init(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            break
        case let .middle(index: index):
            let indexPath = IndexPath.init(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            break
        case .bottom:
            scrollToBottom(animated: true)
            break
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        let section = tableView.numberOfSections - 1
        let row = tableView.numberOfRows(inSection: section) - 1
        let indexPath = IndexPath(row: row, section: section)
        let _ = dataSource.tableView(self.tableView, cellForRowAt: indexPath)
        let t = DispatchTime.now() + TimeInterval(0.001)// magic
        
        DispatchQueue.main.asyncAfter(deadline: t) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}
