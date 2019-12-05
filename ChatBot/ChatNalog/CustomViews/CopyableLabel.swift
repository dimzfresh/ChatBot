//
//  CopyableLabel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/12/2019.
//  Copyright © 2019 di. All rights reserved.
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
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
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
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = prepareText()
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
    
    private func prepareText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let date = formatter.string(from: Date())
        let message = text ?? ""
        let text = "\(date) Пользователь: \(message)"
        return text
    }
}
