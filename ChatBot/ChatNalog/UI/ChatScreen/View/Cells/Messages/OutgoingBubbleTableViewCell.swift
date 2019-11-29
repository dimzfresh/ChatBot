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

final class OutgoingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    private var disposeBag = DisposeBag()
    
    var message: ChatModel? {
        didSet {
            process()
        }
    }
    
    var answers = BehaviorRelay<[AnswerButton]>(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
        bind()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        speakerButton.layer.removeAllAnimations()
    }
}

private extension OutgoingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
    }
    
    func bind() {
        speakerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.animate()            
        }, onDisposed: {
            
        }).disposed(by: disposeBag)
    }
    
    func process() {
        userNameLabel.text = "Пользователь"
        messageLabel.text = message?.text
    }
    
    func animate() {
        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            //let image: UIImage = state == .recording ? #imageLiteral(resourceName: "play_sound_tapped") : #imageLiteral(resourceName: "play_sound")
            self.speakerButton.setImage(#imageLiteral(resourceName: "play_sound_tapped"), for: .normal)
        }) { _ in
//            guard state == .recording else {
//                self.micButton.layer.removeAllAnimations()
//                self.pulseLayers.forEach { $0.removeFromSuperlayer() }
//                self.pulseLayers.removeAll()
//                return
//            }
            
            self.speakerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.speakerButton.alpha = 0.9

            UIView.animate(withDuration: 1.2,
                                       delay: 0,
                                       usingSpringWithDamping: 0.2,
                                       initialSpringVelocity: 5,
                                       options: [.autoreverse, .curveLinear,
                                                 .repeat, .allowUserInteraction],
                                       animations: {
                                        self.speakerButton.transform = .identity
                                        self.speakerButton.alpha = 1
                })
        }
        
    }
}
