//
//  IncomingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

fileprivate typealias AnswerSectionModel = SectionModel<AnswerSection, AnswerItem>

fileprivate enum AnswerSection {
    case main
}

fileprivate enum AnswerItem {
    case button(answer: AnswerButton)
}

final class IncomingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var messageStackView: UIStackView!
    
    @IBOutlet private weak var collectionStackView: UIStackView!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var disposeBag = DisposeBag()
    private var items = BehaviorRelay<[AnswerSectionModel]>(value: [])
    var selectedItem = BehaviorSubject<AnswerButton?>(value: nil)

    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<AnswerSectionModel>(configureCell: configureCell)

    private lazy var configureCell: RxCollectionViewSectionedReloadDataSource<AnswerSectionModel>.ConfigureCell = { [weak self] (_, tableView, indexPath, item) in
        guard let self = self else { return UICollectionViewCell() }
        switch item {
        case .button(let answer):
            return self.buttonCell(indexPath: indexPath, answer: answer)
        }
    }
            
    var message: ChatModel? {
        didSet {
            process()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
        bind()
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//
//        disposeBag = DisposeBag()
//    }
}

private extension IncomingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
        setupCollectionView()
    }
    
    func setupCollectionView() {
        //collectionView.contentInset.top = ArticleCollectionCell.cellMargin
        collectionView.register(AnswerCollectionViewCell.nib, forCellWithReuseIdentifier: AnswerCollectionViewCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        collectionView.rx.itemSelected
            .map { [weak self] indexPath -> AnswerItem? in
                return self?.dataSource[indexPath]
            }
            .subscribe(onNext: { [weak self] item in
                guard let item = item else { return }
                switch item {
                case .button(let answer):
                    self?.selectedItem.on(.next(answer))
                }
            })
            .disposed(by: disposeBag)
    }
    
    func buttonCell(indexPath: IndexPath, answer: AnswerButton) -> UICollectionViewCell {
        guard let cell = collectionView.dequeue(AnswerCollectionViewCell.self, indexPath: indexPath) else {
            return UICollectionViewCell()
        }
        cell.answer = message?.buttons?[indexPath.section]
        return cell
    }
    
    func bind() {
        items
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    func process() {
        selectedItem = BehaviorSubject<AnswerButton?>(value: nil)
        
        userNameLabel.text = "Чатбот"
                
        guard message?.buttons?.isEmpty == false else {
            collectionStackView.isHidden = true
            collectionView.isHidden = true
            messageStackView.alignment = .leading
            messageLabel.text = message?.text
            layoutIfNeeded()
            return }
        
        collectionStackView.isHidden = false
        collectionView.isHidden = false

        var text = message?.text ?? ""
        messageLabel.text = text + (text.isEmpty ? "" : "\n\n") + "\(message?.buttonsDescription ?? "")\n"
        text = messageLabel.text ?? ""
        var current = 1
        var newAnswers = [AnswerSectionModel]()
        message?.buttons?.forEach {
            let description = $0.description ?? ""
            text = text + description
            
            newAnswers.append(AnswerSectionModel(model: .main, items: [.button(answer: $0)]))
            
            if current != message?.buttons?.count, !description.isEmpty  {
                text += "\n"
            }
            current += 1
        }
        
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

        messageLabel.attributedText = attributedString
        
        items.accept(newAnswers)
        
        collectionStackView.alignment = .fill
        messageStackView.alignment = .fill
        collectionStackView.layoutIfNeeded()
    }
}

extension IncomingBubbleTableViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let item = dataSource[section]
        switch item.model {
        case .main:
            return UIEdgeInsets(top: 0.0, left: 2, bottom: 0.0, right: 2)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = dataSource[indexPath]
        switch item {
        case .button(_):
            let count = CGFloat(dataSource.sectionModels.count)
            let width = (UIScreen.main.bounds.width - 28 - 4*count) / count
            return CGSize(width: width, height: 40)
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        
//        let item = items.value[indexPath.section].items[indexPath.row]
//        switch item {
//        case .button(let answer):
//            selectedItem.on(.next(answer))
//        }
//    }
}

