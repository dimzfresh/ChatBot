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
    
    private var isShownPopup: Bool = false
    
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
    
//    override func copy(_ sender: Any?) {
//        let board = UIPasteboard.general
//        board.string = ""
//        board.string = prepareText()
//        let menu = UIMenuController.shared
//        menu.setMenuVisible(false, animated: true)
//    }
    
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        return action == #selector(UIResponderStandardEditActions.copy)
//    }
}

extension Notification.Name {
    static let resetPopupFlag = Notification.Name("resetPopupFlagNotification")
}


private extension CopyableLabel {
    func setup() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showPopup)))
        isShownPopup = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetPopupFlag), name: .resetPopupFlag, object: nil)
    }
    
    @objc
    func resetPopupFlag() {
        isShownPopup = false
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
    
    @objc
    func showPopup() {
        becomeFirstResponder()

        guard !isShownPopup, let parent = UIApplication.shared.windows.first?.rootViewController else { return }
        isShownPopup = true
        
        let popUpVC: ShareViewController = .init()
        popUpVC.shareText = text
        popUpVC.view.frame = UIScreen.main.bounds
        popUpVC.view.translatesAutoresizingMaskIntoConstraints = false
        popUpVC.willMove(toParent: parent)
        
        parent.view.addSubview(popUpVC.view)
        popUpVC.view
            .leadingAnchor(to: parent.view.leadingAnchor)
            .trailingAnchor(to: parent.view.trailingAnchor)
            .topAnchor(to: parent.view.topAnchor)
            .bottomAnchor(to: parent.view.bottomAnchor)
        
        parent.addChild(popUpVC)
        popUpVC.didMove(toParent: parent)
    }
}
