//
//  InputView.swift
//  ChatBot
//
//  Created by iOS dev on 26/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class CustomInputTextView: UITextView {

    // MARK: - public

    public var placeHolderText: String? = "Введите вопрос"

    public lazy var placeHolderLabel: UILabel! = {
        let placeHolderLabel = UILabel(frame: .zero)
        placeHolderLabel.numberOfLines = 0
        placeHolderLabel.backgroundColor = .clear
        placeHolderLabel.textColor = #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 0.5)
        placeHolderLabel.font = .fontTo(.brandFontRegular, size: 14, weight: .medium)
        return placeHolderLabel
    }()

    // MARK: - Init
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        enableNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        enableNotifications()
    }

    // MARK: - Cycle
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func showPlaceholder() {
        animatePlaceholder()
    }
}

private extension CustomInputTextView {
    func setup() {
        textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
        returnKeyType = .done
        font = .fontTo(.brandFontRegular, size: 14, weight: .regular)
        textColor = #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 1)
        
        addSubview(placeHolderLabel)
        placeHolderLabel.frame = CGRect(x: 20, y: 8, width: 130, height: 32)
        placeHolderLabel.text = placeHolderText
        bringSubviewToFront(placeHolderLabel)
    }

    // MARK: - Notifications
    func enableNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChangeNotification(_:)), name: UITextView.textDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChangeNotification(_:)), name: UITextView.textDidEndEditingNotification, object: nil)
    }

    @objc
    func textDidChangeNotification(_ notify: Notification) {
        guard self == notify.object as? UITextView else { return }
        guard placeHolderText != nil else { return }
        
        animatePlaceholder()
    }
    
    func animatePlaceholder() {
        UIView.transition(with: placeHolderLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.placeHolderLabel.alpha = (self.text.count == 0) ? 1 : 0
        })
    }
}
