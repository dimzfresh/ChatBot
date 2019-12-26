//
//  AnswerCollectionViewCell.swift
//  ChatBot
//
//  Created by iOS dev on 23/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class AnswerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var answerButton: AnimatedButton!
                
    var answer: AnswerButton? {
        didSet {
            setupTitle()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }
    
    func animate(_ callback: @escaping () -> Void) {
        answerButton.animate {
            callback()
        }
    }
}

private extension AnswerCollectionViewCell {
    func setup() {
        answerButton.titleLabel?.textAlignment = .center
        answerButton.layer.cornerRadius = 8
        answerButton.clipsToBounds = true
        answerButton.isUserInteractionEnabled = false
    }
    
    func setupTitle() {
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
            answerButton.titleLabel?.font = .fontTo(.brandFontRegular, size: 15, weight: .medium)
            answerButton.setTitle(first + "\n" + second, for: .normal)
        }
    }
}
