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
    
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    var message: ChatModel? {
        didSet {
            process()
        }
    }
    
    var answers = BehaviorRelay<[AnswerButton]>(value: [])
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }
}

private extension OutgoingBubbleTableViewCell {
    func setup() {
        selectionStyle = .none
    }
    
    func process() {
        userNameLabel.text = "Пользователь"
        messageLabel.text = message?.text
    }
}
