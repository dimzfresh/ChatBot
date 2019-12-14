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
import Alamofire

typealias AnswerSectionModel = SectionModel<AnswerSection, AnswerItem>

enum AnswerSection {
    case main
}

enum AnswerItem {
    case button(answer: AnswerButton)
}

final class IncomingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: UIActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: CopyableLabel!
    @IBOutlet private weak var messageStackView: UIStackView!
    
    @IBOutlet private weak var collectionStackView: UIStackView!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    typealias ViewModelType = IncomingViewModel
    var viewModel: ViewModelType! {
        didSet {
            selectedItem = BehaviorSubject<AnswerButton?>(value: nil)
            setupCollectionView()
        }
    }
    
    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = .shared

    var selectedItem = BehaviorSubject<AnswerButton?>(value: nil)
    private var incomingText = BehaviorRelay<String?>(value: nil)
    private var items = BehaviorRelay<[AnswerSectionModel]>(value: [])

    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<AnswerSectionModel>(configureCell: configureCell)

    private lazy var configureCell: RxCollectionViewSectionedReloadDataSource<AnswerSectionModel>.ConfigureCell = { [weak self] (_, tableView, indexPath, item) in
        guard let self = self else { return UICollectionViewCell() }
        switch item {
        case .button(let answer):
            return self.buttonCell(indexPath: indexPath, answer: answer)
        }
    }
    
    var selectedMic = BehaviorRelay<Bool?>(value: nil)
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        clear()
        disposeBag = DisposeBag()
    }
    
    func clear() {
        activity.stopAnimating()
        speakerButton.isHidden = false
        speakerButton.layer.removeAllAnimations()
        speakerButton.setImage(#imageLiteral(resourceName: "play_sound"), for: .normal)
    }
}

// MARK: - BindableType
extension IncomingBubbleTableViewCell: BindableType {
    func bindViewModel() {
        bind()
    }
}

private extension IncomingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
        userNameLabel.text = "Чатбот"
    }
    
    func bind() {
        items
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        incomingText
            .subscribe(onNext: { [weak self] text in
                self?.messageLabel.text = text
            })
            .disposed(by: disposeBag)
        
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self, let vm = self.viewModel else { return }
            self.selectedMic.accept(true)
            let flag = vm.isLoading.value
            vm.isLoading.accept(!flag)
        }).disposed(by: disposeBag)
        
        viewModel?.isLoading
            .subscribe(onNext: { [weak self] flag in
            if flag {
                self?.activity.startAnimating()
                self?.speakerButton.isHidden = true
            }
        })
        .disposed(by: disposeBag)
        
        viewModel?.isPlaying.subscribe(onNext: { [weak self] flag in
            self?.activity.stopAnimating()
            self?.speakerButton.isHidden = false
            self?.animate()
          })
          .disposed(by: disposeBag)
        
        viewModel?.input
            .subscribe(onNext: { [weak self] answer in
                self?.incomingText.accept(answer?.text)
                self?.process(answer: answer)
            })
            .disposed(by: disposeBag)
    }
    
    func process(answer: InputAnswer?) {
        messageLabel.text = answer?.text

        guard answer?.items.isEmpty == false else {
            collectionStackView.isHidden = true
            collectionView.isHidden = true
            messageStackView.alignment = .leading
            layoutIfNeeded()
            items.accept([])
            return }

        collectionStackView.isHidden = false
        collectionView.isHidden = false

        let attributedString = NSMutableAttributedString(string: answer?.text ?? "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

        messageLabel.attributedText = attributedString
        
        collectionStackView.alignment = .fill
        messageStackView.alignment = .fill
        
        items.accept(answer?.items ?? [])
    }
    
    func animate() {
        // Image
        let image: UIImage = viewModel.isPlaying.value ? #imageLiteral(resourceName: "play_sound_tapped") : #imageLiteral(resourceName: "play_sound")

        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        guard viewModel.isPlaying.value else {
            speakerButton.transform = .identity
            speakerButton.alpha = 1
            speakerButton.layer.removeAllAnimations()
            return
        }
        
        // Scale
        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 5,
                       options: [.autoreverse, .curveLinear,
                                 .repeat, .allowUserInteraction],
                       animations: {
                        self.speakerButton.transform = .identity
                        self.speakerButton.alpha = 0.75
        })
    }
}


// MARK: - CollectionView
private extension IncomingBubbleTableViewCell {
    func setupCollectionView() {
        collectionView.register(AnswerCollectionViewCell.nib, forCellWithReuseIdentifier: AnswerCollectionViewCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
//        collectionView.rx.itemSelected
//            .map { [weak self] indexPath -> AnswerItem? in
//                return self?.dataSource[indexPath]
//            }
//            .subscribe(onNext: { [weak self] item in
//                guard let item = item else { return }
//                switch item {
//                case .button(let answer):
//                    self?.selectedItem.on(.next(answer))
//                }
//            })
        //.disposed(by: disposeBag)
    }
    
    func buttonCell(indexPath: IndexPath, answer: AnswerButton) -> UICollectionViewCell {
        guard let cell = collectionView.dequeue(AnswerCollectionViewCell.self, indexPath: indexPath) else {
            return UICollectionViewCell()
        }
        
        let item = dataSource[indexPath]
        guard case let AnswerItem.button(answer) = item else {
            return UICollectionViewCell()
        }
        
        cell.answer = answer
        cell.selectedItem?.subscribe({ [weak self] answer in
            self?.selectedItem.on(answer.event)
        }).disposed(by: disposeBag)
        
        return cell
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

