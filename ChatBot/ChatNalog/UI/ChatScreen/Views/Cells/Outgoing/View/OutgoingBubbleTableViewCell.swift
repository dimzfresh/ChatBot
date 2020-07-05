//
//  OutgoingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import NVActivityIndicatorView

final class OutgoingBubbleTableViewCell: UITableViewCell {
    // MARK: - Outlets
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: NVActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: CustomTextView!
    
    typealias ViewModelType = OutgoingViewModel
    var viewModel: ViewModelType!
    
    private var selectedMicSubject = BehaviorSubject<Bool>(value: false)
//    var selectedMic: Observable<Bool> {
//        return selectedMicSubject.asObservable()
//    }
    var onSelectMic: (() -> Void)?
    
    private var player: VoiceManager? = .shared
    private var disposeBag = DisposeBag()
        
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
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
extension OutgoingBubbleTableViewCell: BindableType {
    func bindViewModel() {
        bind()
    }
}

private extension OutgoingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
        userNameLabel.text = "Пользователь"
        activity.color = #colorLiteral(red: 0.6274509804, green: 0.368627451, blue: 0.7921568627, alpha: 1).withAlphaComponent(0.6)
        activity.type = .circleStrokeSpin
    }
    
    func bind() {
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
            .map({
                let attributedString = NSMutableAttributedString(string: $0?.text ?? "")
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .regular), range: NSMakeRange(0, attributedString.length))
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), range: NSMakeRange(0, attributedString.length))
                return attributedString
            })
            .bind(to: messageLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
        bindSpeakerTap()
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

