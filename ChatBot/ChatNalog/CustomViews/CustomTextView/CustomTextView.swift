//
//  CustomTextView.swift
//  ChatBot
//
//  Created by iOS dev on 06/12/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

extension Notification.Name {
    static let resetPopupFlag = Notification.Name("resetPopupFlagNotification")
}

final class CustomTextView: UITextView {
    
    @IBInspectable
    var isUser: Bool = false
        
    private var isShownPopup: Bool = false
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: nil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

private extension CustomTextView {
    func setup() {
        isScrollEnabled = false
        isEditable = false
        //isSelectable = false
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showPopup)))
        isShownPopup = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetPopupFlag), name: .resetPopupFlag, object: nil)
    }
    
    @objc func resetPopupFlag() {
        isShownPopup = false
    }
    
    @objc func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func showPopup() {
        UIMenuController.shared.setMenuVisible(false, animated: false)
        
        becomeFirstResponder()

        guard !isShownPopup, let parent = UIApplication.shared.windows.first?.rootViewController else { return }
        isShownPopup = true
        
        let popUpVC: ShareViewController = .init()
        popUpVC.shareText = text ?? " "
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
