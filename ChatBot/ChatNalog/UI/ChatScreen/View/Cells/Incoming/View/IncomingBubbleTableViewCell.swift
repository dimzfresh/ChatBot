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

fileprivate typealias AnswerSectionModel = SectionModel<AnswerSection, AnswerItem>

fileprivate enum AnswerSection {
    case main
}

fileprivate enum AnswerItem {
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
    
    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = VoiceManager.shared

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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activity.stopAnimating()
        player?.stopPlaying()
        isPlaying.accept(false)
    }
}

private extension IncomingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
        setupCollectionView()
        
        //addLongPressRecognizer()
    }
    
    func addLongPressRecognizer() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        addGestureRecognizer(longPressRecognizer)
    }

    @objc
    func longPressed() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let date = formatter.string(from: Date())
        let mess = message?.text ?? ""
        let text = "\(date) Чатбот: \(mess)"
        copyToClipboard(text: text)
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
        
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let flag = self.isPlaying.value
            self.isPlaying.accept(!flag)
        }).disposed(by: disposeBag)
        
        isPlaying.subscribe(onNext: { [weak self] flag in
            self?.load()
            self?.animate()
        })
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
    
    func animate() {
        // Image
        let image: UIImage = isPlaying.value ? #imageLiteral(resourceName: "play_sound_tapped") : #imageLiteral(resourceName: "play_sound")

        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        guard isPlaying.value else {
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
    
    func load() {
        guard let text = message?.text, isPlaying.value else {
            activity.stopAnimating()
            speakerButton.isHidden = false
            return }
        
        activity.startAnimating()
        speakerButton.isHidden = true
        
        cancelAllRequests()
        
        service.synthesize(text: text)
        .subscribe(onNext: { [weak self] model in
            self?.activity.stopAnimating()
            self?.speakerButton.isHidden = false
            self?.convertAndPlay(text: model.someString)
            })
        .disposed(by: disposeBag)
    }
    
    func cancelAllRequests() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }
    
    func convertAndPlay(text : String?) {
        guard let audioData = Data(base64Encoded: text ?? "", options: .ignoreUnknownCharacters) else { return }
        
        let filename = getDocumentsDirectory().appendingPathComponent("input.mp3")
        do {
            try audioData.write(to: filename, options: .atomicWrite)
        } catch (let error) {
            print(error)
        }
        player?.startPlaying()
        player?.audioPlayerDidFinished = { [weak self] in
            self?.isPlaying.accept(false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
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

