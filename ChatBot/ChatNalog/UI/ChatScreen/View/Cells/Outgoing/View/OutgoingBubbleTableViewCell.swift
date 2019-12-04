//
//  OutgoingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class OutgoingBubbleTableViewCell: UITableViewCell, BindableType {
    typealias ViewModelType = OutgoingViewModel
    var viewModel: ViewModelType!
    
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: UIActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!

    private var disposeBag = DisposeBag()

    private let service = ChatService()
    private var isPlaying = BehaviorRelay<Bool>(value: false)
    private var player: VoiceManager? = VoiceManager.shared
    
    var answers = BehaviorRelay<[AnswerButton]>(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activity.stopAnimating()
        player?.stopPlaying()
        isPlaying.accept(false)
    }
    
    func bindViewModel() {
        bind()
    }
}

private extension OutgoingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
        userNameLabel.text = "Пользователь"
    }
    
    func bind() {
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let flag = self.isPlaying.value
            self.isPlaying.accept(!flag)
        }).disposed(by: disposeBag)
        
        isPlaying.subscribe(onNext: { [weak self] flag in
            self?.viewModel?.load()
            self?.animate()
        })
        .disposed(by: disposeBag)
        
        viewModel?.input
            .subscribe(onNext: { [weak self] message in
                self?.messageLabel.text = message?.text
            })
            .disposed(by: disposeBag)
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
}

