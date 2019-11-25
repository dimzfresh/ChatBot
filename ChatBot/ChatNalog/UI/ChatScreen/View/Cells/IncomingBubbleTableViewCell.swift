//
//  IncomingBubbleTableViewCell.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit

final class IncomingBubbleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var message: ChatModel? {
        didSet {
            userNameLabel.text = "Чатбот"
            messageLabel.text = message?.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
}

private extension IncomingBubbleTableViewCell {
    func setup() {
        selectionStyle = .blue
    }
}

