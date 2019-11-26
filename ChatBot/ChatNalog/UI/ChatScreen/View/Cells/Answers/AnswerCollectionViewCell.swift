//
//  AnswerCollectionViewCell.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class AnswerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var answerButton: AnimatedButton!
    
    private var disposeBag = DisposeBag()
    
    var answer: AnswerButton? {
        didSet {
            answerButton.setTitle(answer?.name, for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

private extension AnswerCollectionViewCell {
    func setup() {
        answerButton.layer.cornerRadius = 4
//        answerButton.rx.tap.subscribe(onNext: { _ in
//            
//        })
//        .disposed(by: disposeBag)
    }
}
