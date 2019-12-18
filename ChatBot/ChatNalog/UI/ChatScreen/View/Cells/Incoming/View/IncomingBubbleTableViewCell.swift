//
//  IncomingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
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
            selectedAnswerSubject = BehaviorSubject<AnswerButton?>(value: nil)
        }
    }
    
    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = .shared

    private var selectedAnswerSubject = BehaviorSubject<AnswerButton?>(value: nil)
    var selectedItem: Observable<AnswerButton?> { selectedAnswerSubject.asObservable() }
    
    private var selectedMicSubject = BehaviorSubject<Bool?>(value: nil)
    var selectedMic: Observable<Bool?> { selectedMicSubject.asObservable() }
    
    private var incomingText = BehaviorSubject<String?>(value: nil)
    private var items: [AnswerSectionModel] = [] {
        didSet {
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
            }
        }
    }
        
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
        setupCollectionView()
    }
    
    func bind() {
        incomingText
            .map { $0 }
            .bind(to: messageLabel.rx.text)
            .disposed(by: disposeBag)
        
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self, let vm = self.viewModel else { return }
            self.selectedMicSubject.onNext(true)
            self.selectedMicSubject.onCompleted()
            
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
        
        viewModel?.isPlaying
            .subscribe(onNext: { [weak self] flag in
                self?.activity.stopAnimating()
                self?.speakerButton.isHidden = false
                self?.animate()
            })
            .disposed(by: disposeBag)
        
        viewModel?.input
            .subscribe(onNext: { [weak self] answer in
                self?.incomingText.onNext(answer?.text)
                self?.process(answer: answer)
            })
            .disposed(by: disposeBag)
        
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = true
        tapGesture.delaysTouchesBegan = true

        collectionView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { [weak self] recognizer in
            guard recognizer.state == .ended else { return }
            let location = recognizer.location(in: self?.collectionView)
            guard let tapIndexPath = self?.collectionView.indexPathForItem(at: location)
                else { return }
            
            let cell = self?.collectionView.cellForItem(at: tapIndexPath) as? AnswerCollectionViewCell
            cell?.animate { [weak self] in
                guard let self = self else { return }
                let item = self.items[tapIndexPath.section].items[tapIndexPath.row]
                guard case let AnswerItem.button(answer) = item else { return }
                
                self.selectedAnswerSubject.on(.next(answer))
                self.selectedAnswerSubject.onCompleted()
            }
            
        }).disposed(by: disposeBag)
    }
    
    func process(answer: InputAnswer?) {
        messageLabel.text = answer?.text

        guard answer?.items.isEmpty == false else {
            collectionStackView.isHidden = true
            collectionView.isHidden = true
            messageStackView.alignment = .leading
            //items.accept([])
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
        
        //items.accept(answer?.items ?? [])
        items = answer?.items ?? []
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
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.isUserInteractionEnabled = true
        collectionView.isScrollEnabled = false
    }
    
    func buttonCell(indexPath: IndexPath, answer: AnswerButton) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnswerCollectionViewCell.identifier, for: indexPath) as? AnswerCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.answer = answer
        return cell
    }
}

extension IncomingBubbleTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].items.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.section].items[indexPath.row]
        guard case let AnswerItem.button(answer) = item else {
            return UICollectionViewCell()
        }

        return buttonCell(indexPath: indexPath, answer: answer)
    }
}

extension IncomingBubbleTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 2, bottom: 0.0, right: 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let count = CGFloat(items.count)
        let width = (UIScreen.main.bounds.width - 28 - 4*count) / count
        return CGSize(width: width, height: 40)
    }
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        let cell = collectionView.cellForItem(at: indexPath) as? AnswerCollectionViewCell
//        cell?.animate { [weak self] in
//            guard let self = self else { return }
//            let item = self.items[indexPath.section].items[indexPath.row]
//            guard case let AnswerItem.button(answer) = item else { return }
//
//            self.selectedAnswerSubject.on(.next(answer))
//        }
//    }
}
