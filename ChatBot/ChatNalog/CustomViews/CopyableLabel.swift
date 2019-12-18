//
//  CopyableLabel.swift
//  ChatBot
//
//  Created by iOS dev on 06/12/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class CopyableLabel: UILabel {
    
    @IBInspectable
    var isUser: Bool = false
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = ""
        board.string = prepareText()
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}

private extension CopyableLabel {
    func setup() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showMenu)))
    }
    
    @objc
    func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    func prepareText() -> String {
        let formatter = DateFormatter()
        //formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.dateFormat = "HH:mm, dd.MM.yyyy"
        let date = formatter.string(from: Date())
        let message = text ?? ""
        let name = isUser ? "Пользователь" : "Бот"
        let text = "[\(date)] \(name): \(message)"
        return text
    }
}
