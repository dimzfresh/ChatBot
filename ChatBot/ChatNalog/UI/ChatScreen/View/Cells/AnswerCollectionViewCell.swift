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
    
    @IBOutlet private weak var answerButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

}

private extension AnswerCollectionViewCell {
    func setup() {
        answerButton.rx.tap.subscribe(onNext: { _ in
            
        })
        .disposed(by: disposeBag)
        
    }
}
