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

final class OutgoingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var activity: UIActivityIndicatorView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: CopyableLabel!
    
    typealias ViewModelType = OutgoingViewModel
    var viewModel: ViewModelType!
    
    private var selectedMicSubject = BehaviorSubject<Bool?>(value: nil)
    var selectedMic: Observable<Bool?> { selectedMicSubject.asObservable() }
    
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
    }
    
    func bind() {
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
        
        viewModel?.isPlaying.subscribe(onNext: { [weak self] flag in
            self?.activity.stopAnimating()
            self?.speakerButton.isHidden = false
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
        let image: UIImage = viewModel.isPlaying.value ? #imageLiteral(resourceName: "chat_mic_on") : #imageLiteral(resourceName: "chat_mic_off")

        UIView.transition(with: speakerButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.speakerButton.setImage(image, for: .normal)
        })
        
        speakerButton.transform = .init(scaleX: 0.9, y: 0.9)
        
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

