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
import NVActivityIndicatorView

typealias AnswerSectionModel = SectionModel<AnswerSection, AnswerItem>

enum AnswerSection {
    case main
}

enum AnswerItem {
    case button(answer: AnswerButton)
}

final class IncomingBubbleTableViewCell: UITableViewCell {
    // MARK: - Outlets
    @IBOutlet private weak var bubbleView: BubbleView!
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: NVActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: CopyableLabel!
    @IBOutlet private weak var messageStackView: UIStackView!
    
    @IBOutlet private weak var answerButtonsStackView: UIStackView!
    @IBOutlet private weak var firstFiveStackView: UIStackView!
    @IBOutlet private weak var secondFiveStackView: UIStackView!
    
    @IBOutlet private var answerButtons: [AnimatedButton]!
    private var indexButtons: Observable<Int>?
        
    @IBOutlet private weak var shareButton: UIButton!
    
    private let eventLogger: FirebaseEventManager = .shared
        
    typealias ViewModelType = IncomingViewModel
    var viewModel: ViewModelType! {
        didSet {
            selectedAnswerSubject = BehaviorSubject<AnswerButton?>(value: nil)
        }
    }
        
    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var player: VoiceManager? = .shared

    private var selectedAnswerSubject = BehaviorSubject<AnswerButton?>(value: nil)
    var selectedItem: Observable<AnswerButton?> { selectedAnswerSubject.asObservable() }
    
    private var selectedMicSubject = BehaviorSubject<Bool>(value: false)
    //var selectedMic: Observable<Bool> { selectedMicSubject.asObservable() }
    var onSelectMic: (() -> Void)?
    
    private var incomingText = BehaviorSubject<String?>(value: nil)
    
    private var items: [AnswerSectionModel] = []

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addShadow()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clear()
        disposeBag = DisposeBag()
    }
    
    // MARK: - Funcs
    func cofigure(selected: Bool) {
        guard selected else { return }
        
        if player?.isPlaying == true {
            startAnimation()
        }
        
        viewModel.isPlaying.accept(player?.isPlaying)
        viewModel.isOnPause.accept(player?.isOnPause)
    }
    
    func clear() {
        activity.stopAnimating()
        speakerButton.isHidden = false
        stopAnimation()
        viewModel.resetFlags()
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
        addShadow()
        activity.color = #colorLiteral(red: 0.3411764706, green: 0.3019607843, blue: 0.7921568627, alpha: 1).withAlphaComponent(0.6)
        activity.type = .circleStrokeSpin
    }
    
    func addShadow() {
        guard bubbleView.layer.shadowOpacity == 0 else { return }
        //let shadowPath = UIBezierPath(roundedRect: bubbleView.bounds, cornerRadius: 0)
        //bubbleView.layer.shadowPath = shadowPath.cgPath
        bubbleView.layer.shadowColor = UIColor(red: 0.487, green: 0.53, blue: 0.587, alpha: 0.2).cgColor
        bubbleView.layer.shadowRadius = 15
        bubbleView.layer.shadowOffset = .init(width: 0, height: 6)
        //bubbleView.layer.shouldRasterize = true
        bubbleView.layer.rasterizationScale = UIScreen.main.scale
        //bubbleView.layer.bounds = bubbleView.bounds
        bubbleView.layer.masksToBounds = false
        bubbleView.layer.shadowOpacity = 0.7
    }
    
    func bind() {
        incomingText
            .map { $0 }
            .bind(to: messageLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel?.isPlaying
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag else { return }
                if flag {
                    self?.startAnimation()
                } else {
                    self?.stopAnimation()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel?.isOnPause
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag, flag else { return }
                self?.showPause()
            })
            .disposed(by: disposeBag)
        
        viewModel?.isLoading
            .subscribe(onNext: { [weak self] flag in
                guard let flag = flag else { return }
                if flag {
                    self?.activity.startAnimating()
                    self?.speakerButton.isHidden = true
                } else {
                    self?.activity.stopAnimating()
                    self?.speakerButton.isHidden = false
                    self?.startAnimation()
                }
        })
        .disposed(by: disposeBag)
        
        viewModel?.input
            .subscribe(onNext: { [weak self] answer in
                self?.incomingText.onNext(answer?.text)
                self?.process(answer: answer)
            })
            .disposed(by: disposeBag)
        
        shareButton.rx.tap
            .throttle(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                self?.share()
        }).disposed(by: disposeBag)
        
        bindSpeakerTap()
        bindAnswerTap()
    }
    
    func bindSpeakerTap() {
        speakerButton.rx.tap
            .throttle(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] in
                self.onSelectMic?()
                
                let vm = self.viewModel
                let isLoading = vm?.isLoading.value ?? false
                let isPlaying = vm?.isPlaying.value ?? false
                let isOnPause = vm?.isOnPause.value ?? false

                if !isPlaying, !isOnPause, !isLoading {
                    vm?.isLoading.accept(true)
                } else if isPlaying, !isOnPause, !isLoading {
                    vm?.isOnPause.accept(true)
                } else if isOnPause {
                    vm?.isOnPause.accept(false)
                    vm?.isPlaying.accept(true)
                }
        })
        .disposed(by: disposeBag)
    }
    
    func bindAnswerTap() {
        let taps = answerButtons.enumerated().map { ($0.0, $0.1.rx.tap) }
        let toInts = taps.map { index, obs in obs.map { index } }
        indexButtons = Observable.merge(toInts)
        
        indexButtons?
            .throttle(.milliseconds(250), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                
                self.eventLogger.logEvent(input: .init(.chat(.answerButton)))
                
                let button = self.answerButtons[index]
                button.animate { [weak self] in
                    guard let self = self else { return }
                    guard let item = self.items[index].items.first,
                        case let AnswerItem.button(answer) = item else { return }
                    
                    self.selectedAnswerSubject.on(.next(answer))
                    self.selectedAnswerSubject.onCompleted()
                }
            }).disposed(by: disposeBag)
    }
    
    func getSubviewsOfView(v: UIView) -> [AnimatedButton] {
        var buttonArray = [AnimatedButton]()
        
        v.subviews.forEach {
            buttonArray += getSubviewsOfView(v: $0)

              if let button = $0 as? AnimatedButton {
                  buttonArray.append(button)
              }
        }

        return buttonArray
    }
    
    func share() {
        let root = UIApplication.shared.windows.first?.rootViewController
        root?.share(text: prepareText())
    }
    
    func prepareText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, dd.MM.yyyy"
        let date = formatter.string(from: Date())
        let message = messageLabel.text ?? ""
        
        // TODO: -Temporary
        let preparedText = message.replacingOccurrences(of: "Удовлетворены ли вы нашим ответом на Ваш вопрос?", with: "Подробнее можно посмотреть на сайте https://asknpd.ru/")
        
        if preparedText.isEmpty {
            return ""
        } else {
            return "[\(date)]: \(preparedText)"
        }
    }
    
    func process(answer: InputAnswer?) {
        messageLabel.text = answer?.text

        guard answer?.items.isEmpty == false else {
            answerButtonsStackView.isHidden = true
            firstFiveStackView.isHidden = true
            secondFiveStackView.isHidden = true
            answerButtons.forEach { $0.isHidden = true }
            return }

        let count = answer?.items.count ?? 0
        answerButtonsStackView.isHidden = false
        firstFiveStackView.isHidden = !(count <= 6)
        secondFiveStackView.isHidden = !(count > 6)
        
        var attributedString: NSMutableAttributedString
        let sentenses = answer?.text.split(separator: "\n")
        if sentenses?.count ?? 0 >= 2, sentenses?.last != "\n" {
            let first = String(sentenses?.first ?? "")
            let subtitle = answer?.text.replacingOccurrences(of: first, with: "")
            attributedString = NSMutableAttributedString(string: first + "\n")
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .bold), range: NSMakeRange(0, attributedString.length))
            var string = subtitle ?? ""
            if string.last == "\n" {
                string.removeLast()
            }
            attributedString.append(NSMutableAttributedString(string: string))
        } else {
            var string = answer?.text ?? ""
            if string.last == "\n" {
                string.removeLast()
            }
            attributedString = NSMutableAttributedString(string: string)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        //paragraphStyle.alignment = .center
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        let links = answer?.text.components(separatedBy: "http")
        if links?.isEmpty == false {
            
            //            attributedString.addAttribute(NSAttributedString.Key.link, value: url, range: NSMakeRange(0, attributedString.length))
            
        }
//        if let url = URL(string: "http://www.google.com") {
//            attributedString.addAttribute(NSAttributedString.Key.link, value: url, range: NSMakeRange(0, attributedString.length))
//        }
        
        messageLabel.attributedText = attributedString
                        
        let items = answer?.items ?? []
        self.items = items
        processButtons(items: items)
    }
    
    func processButtons(items: [AnswerSectionModel]) {
        guard items.count <= answerButtons.count else { return }
        
        for index in 0..<answerButtons.count {
            let answerButton = answerButtons[index]
            answerButton.isHidden = false
            
            if !items.indices.contains(index) {
                answerButton.isHidden = true
                continue
            }
            
            guard let item = items[index].items.first,
                case let AnswerItem.button(answer) = item else { return }

            let name = answer.name ?? ""
            var result = name.split(separator: " ")
            if result.count <= 1 {
                answerButton.setTitle(name, for: .normal)
            } else {
                let first = result.removeFirst()
                let second = result.reduce("") { res, sub -> String in
                    return  res + sub + " "
                }
                answerButton.titleLabel?.numberOfLines = 0
                answerButton.titleLabel?.lineBreakMode = .byWordWrapping
                answerButton.titleLabel?.textAlignment = .center
                answerButton.titleLabel?.font = .fontTo(.brandFontRegular, size: 15, weight: .medium)
                if items.count > 1 {
                    answerButton.setTitle(first + "\n" + second, for: .normal)
                } else {
                    answerButton.setTitle(first + " " + second, for: .normal)
                }
            }
        }
    }
    
    func showPause() {
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(#imageLiteral(resourceName: "input_play"), for: .normal)
            self.speakerButton.alpha = 1
            self.speakerButton.layer.removeAllAnimations()
        })
    }
    
    func startAnimation() {
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(#imageLiteral(resourceName: "chat_mic_on"), for: .normal)
        })

        speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 5,
                       options: [.curveLinear, .repeat, .allowUserInteraction],
                       animations: {
                        self.speakerButton.transform = .identity
                        self.speakerButton.alpha = 0.75
        })
    }
    
    func stopAnimation() {
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(#imageLiteral(resourceName: "chat_mic_off"), for: .normal)
        })
        
        speakerButton.alpha = 1
        speakerButton.layer.removeAllAnimations()
    }
}

