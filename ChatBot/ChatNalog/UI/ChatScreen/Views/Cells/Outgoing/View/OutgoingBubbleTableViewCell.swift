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
    
    func clear() {
        activity.stopAnimating()
        speakerButton.isHidden = false
        speakerButton.layer.removeAllAnimations()
        speakerButton.setImage(#imageLiteral(resourceName: "chat_mic_off"), for: .normal)
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
            self.onSelectMic?()
            
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
            .map({ NSAttributedString(string: $0?.text ?? "") })
            .bind(to: messageLabel.rx.attributedText)
            .disposed(by: disposeBag)
    }
    
    func animate() {
        let image: UIImage = (viewModel.isPlaying.value ?? false) ? #imageLiteral(resourceName: "chat_mic_on") : #imageLiteral(resourceName: "chat_mic_off")
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        guard let flag = viewModel.isPlaying.value, flag else {
            speakerButton.alpha = 1
            speakerButton.layer.removeAllAnimations()
            return
        }
        
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
}

