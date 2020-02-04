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
    @IBOutlet private weak var messageLabel: CopyableLabel!
    
    typealias ViewModelType = OutgoingViewModel
    var viewModel: ViewModelType!
    
    private var selectedMicSubject = BehaviorSubject<Bool>(value: false)
//    var selectedMic: Observable<Bool> {
//        return selectedMicSubject.asObservable()
//    }
    var onSelectMic: (() -> Void)?
    
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
    func cofigure(onPause: Bool) {
        guard onPause, VoiceManager.shared.onPause else { return }
        
        viewModel.onPause.accept(true)
    }
    
    func clear() {
        activity.stopAnimating()
        speakerButton.isHidden = false
        stopAnimation()
        viewModel.onPause.accept(false)
        viewModel.isPlaying.accept(false)
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
        
        viewModel?.onPause
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
            .map({ NSAttributedString(string: $0?.text ?? "") })
            .bind(to: messageLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
        bindSpeakerTap()
    }
    
    func bindSpeakerTap() {
        speakerButton.rx.tap
            .throttle(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let viewModel = self?.viewModel else { return }
                
                var selected = false
                do {
                    selected = try self?.selectedMicSubject.value() ?? false
                } catch {
                    selected = false
                }
                self?.selectedMicSubject.onNext(selected)
                self?.selectedMicSubject.onCompleted()
                self?.onSelectMic?()
                
                let isPlaying = viewModel.isPlaying.value ?? false
                let onPause = viewModel.onPause.value ?? false
                
                if isPlaying, !onPause {
                    viewModel.onPause.accept(true)
                } else if onPause {
                    viewModel.onPause.accept(false)
                    self?.startAnimation()
                } else {
                    viewModel.isPlaying.accept(!isPlaying)
                }
        })
        .disposed(by: disposeBag)
    }
    
    func showPause() {
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(#imageLiteral(resourceName: "input_pause"), for: .normal)
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
                       options: [.autoreverse, .curveLinear,
                                 .repeat, .allowUserInteraction],
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

