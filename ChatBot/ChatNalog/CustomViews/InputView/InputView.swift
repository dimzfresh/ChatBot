//
//  InputView.swift
//  ChatBot
//
//  Created by iOS dev on 26/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class CustomInputView: UITextView {

    // MARK: - public

    public var placeHolderText: String? = "Введите вопрос"

    public lazy var placeHolderLabel: UILabel! = {
        let placeHolderLabel = UILabel(frame: .zero)
        placeHolderLabel.numberOfLines = 0
        placeHolderLabel.backgroundColor = .clear
        placeHolderLabel.font = .systemFont(ofSize: 16, weight: .regular)
        placeHolderLabel.alpha = 0.5
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

        textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 8)
        returnKeyType = .done
        addSubview(placeHolderLabel)
        placeHolderLabel.frame = CGRect(x: 8, y: 8, width: bounds.size.width - 16, height: 15)
        placeHolderLabel.textColor = textColor
        placeHolderLabel.font = font
        placeHolderLabel.text = placeHolderText
        bringSubviewToFront(placeHolderLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
}

private extension CustomInputView {
    func setup() {
        placeHolderLabel.frame = CGRect(x: 8, y: 8, width: bounds.size.width - 16, height: 15)
        placeHolderLabel.sizeToFit()
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

        UIView.animate(withDuration: 0.25, animations: {
            self.placeHolderLabel.alpha = (self.text.count == 0) ? 0.5 : 0
        }, completion: nil)
    }
}
