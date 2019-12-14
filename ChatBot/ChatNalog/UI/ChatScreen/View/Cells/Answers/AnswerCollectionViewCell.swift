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
            setupTitle()
            bind()
        }
    }
    var selectedItem: BehaviorSubject<AnswerButton?>?
    
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
        answerButton.titleLabel?.textAlignment = .center
        answerButton.layer.cornerRadius = 4
    }
    
    func bind() {
        answerButton.rx.tap.subscribe({ [weak self] _ in
            self?.animate {
                self?.selectedItem?.on(.next(self?.answer))
            }
        }).disposed(by: disposeBag)
    }
    
    func setupTitle() {
        selectedItem = BehaviorSubject<AnswerButton?>(value: nil)

        let name = answer?.name ?? ""
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
            answerButton.setTitle(first + "\n" + second, for: .normal)
        }
    }
    
    func animate(_ callback: @escaping () -> Void) {
        answerButton.animate {
            callback()
        }
    }
}
