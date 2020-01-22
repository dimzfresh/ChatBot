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
import NVActivityIndicatorView

typealias AnswerSectionModel = SectionModel<AnswerSection, AnswerItem>

enum AnswerSection {
    case main
}

enum AnswerItem {
    case button(answer: AnswerButton)
}

final class IncomingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var bubbleView: BubbleView!
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: NVActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: CopyableLabel!
    @IBOutlet private weak var messageStackView: UIStackView!
    
    @IBOutlet private weak var answerButtonsStackView: UIStackView!
    @IBOutlet private var answerButtons: [AnimatedButton]!
    
    @IBOutlet private weak var shareButton: UIButton!
        
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
    var selectedMic: Observable<Bool> { selectedMicSubject.asObservable() }
    
    private var incomingText = BehaviorSubject<String?>(value: nil)
    
    private var items: [AnswerSectionModel] = []

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
    
    func clear() {
        activity.stopAnimating()
        speakerButton.isHidden = false
        speakerButton.layer.removeAllAnimations()
        speakerButton.setImage(#imageLiteral(resourceName: "chat_mic_off"), for: .normal)
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
        
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self, let vm = self.viewModel else { return }
            var selected = false
            do {
                selected = try self.selectedMicSubject.value()
            } catch {
                selected = false
            }
            self.selectedMicSubject.onNext(selected)
            self.selectedMicSubject.onCompleted()
            
            let flag = vm.isPlaying.value ?? false
            vm.isPlaying.accept(!flag)
        }).disposed(by: disposeBag)
        
        viewModel?.isPlaying
            .subscribe(onNext: { [weak self] flag in
                self?.animate()
        })
        .disposed(by: disposeBag)
        
        viewModel?.isLoading
            .subscribe(onNext: { [weak self] flag in
                if flag {
                    self?.activity.startAnimating()
                    self?.speakerButton.isHidden = true
                } else {
                    self?.activity.stopAnimating()
                    self?.speakerButton.isHidden = false
                    self?.animate()
                }
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

        answerButtonsStackView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] recognizer in
            guard recognizer.state == .ended else { return }
            
            let tapLocation = recognizer.location(in: recognizer.view)
            let filteredSubviews = self?.answerButtonsStackView.subviews.filter {
                $0.frame.contains(tapLocation)
            }

            //let button = self?.answerButtonsStackView.hitTest(tapLocation, with: nil)
            guard let button = filteredSubviews?.first as? AnimatedButton,
                let index = self?.answerButtons.firstIndex(of: button) else { return }
            
            button.animate { [weak self] in
                guard let self = self else { return }
                guard let item = self.items[index].items.first,
                    case let AnswerItem.button(answer) = item else { return }

                self.selectedAnswerSubject.on(.next(answer))
                self.selectedAnswerSubject.onCompleted()
            }
        }).disposed(by: disposeBag)
        
        shareButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.share()
        }).disposed(by: disposeBag)
    }
    
    func share() {
        let root = UIApplication.shared.windows.first?.rootViewController
        let activityVC = UIActivityViewController(activityItems: [messageLabel.text ?? ""] as [Any], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad, let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = root?.view
            popoverController.permittedArrowDirections = .down
        } else {
            activityVC.navigationController?.navigationBar.tintColor = .lightGray
        }
        root?.present(activityVC, animated: true)
    }
    
    func process(answer: InputAnswer?) {
        messageLabel.text = answer?.text

        guard answer?.items.isEmpty == false else {
            answerButtonsStackView.isHidden = true
            answerButtons.forEach { $0.isHidden = true }
            return }

        answerButtonsStackView.isHidden = false
        
        var attributedString: NSMutableAttributedString
        let sentenses = answer?.text.split(separator: "\n")
        if sentenses?.isEmpty == false {
            let first = String(sentenses?.first ?? "")
            let subtitle = answer?.text.replacingOccurrences(of: first, with: "")
            attributedString = NSMutableAttributedString(string: first + "\n")
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .bold), range: NSMakeRange(0, attributedString.length))
            attributedString.append(NSMutableAttributedString(string: subtitle ?? ""))
        } else {
            attributedString = NSMutableAttributedString(string: answer?.text ?? "")
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

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
                answerButton.titleLabel?.font = .fontTo(.brandFontRegular, size: 15, weight: .medium)
                answerButton.setTitle(first + "\n" + second, for: .normal)
            }
        }
    }
    
    func animate() {
        // Image
        let image: UIImage = (viewModel.isPlaying.value ?? false) ? #imageLiteral(resourceName: "chat_mic_on") : #imageLiteral(resourceName: "chat_mic_off")

        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        guard let flag = viewModel.isPlaying.value, flag else {
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

