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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let superBool = super.point(inside: point, with: event)
        
        // Configure NSTextContainer
        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        
        // Configure NSLayoutManager and add the text container
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        guard let attributedText = attributedText, let font = font else { return false }
        
        // Configure NSTextStorage and apply the layout manager
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, attributedText.length))
        textStorage.addLayoutManager(layoutManager)
        
        // get the tapped character location
        let locationOfTouchInLabel = point
        
        // account for text alignment and insets
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        var alignmentOffset: CGFloat!
        switch textAlignment {
        case .left, .natural, .justified:
            alignmentOffset = 0.0
        case .center:
            alignmentOffset = 0.5
        case .right:
            alignmentOffset = 1.0
        @unknown default:
            fatalError()
        }
        
        let xOffset = ((bounds.size.width - textBoundingBox.size.width) * alignmentOffset) - textBoundingBox.origin.x
        let yOffset = ((bounds.size.height - textBoundingBox.size.height) * alignmentOffset) - textBoundingBox.origin.y
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - xOffset, y: locationOfTouchInLabel.y - yOffset)
        
        // work out which character was tapped
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // work out how many characters are in the string up to and including the line tapped, to ensure we are not off the end of the character string
        let lineTapped = Int(ceil(locationOfTouchInLabel.y / font.lineHeight)) - 1
        let rightMostPointInLineTapped = CGPoint(x: bounds.size.width, y: font.lineHeight * CGFloat(lineTapped))
        let charsInLineTapped = layoutManager.characterIndex(for: rightMostPointInLineTapped, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        guard characterIndex < charsInLineTapped else { return false }
        
        let attributeName = NSAttributedString.Key.link
        
        let attributeValue = self.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil)
        
        if let value = attributeValue, let url = value as? URL  {
            UIApplication.shared.open(url)
        }
        
        return superBool
    }
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
    
//    func prepareText() -> String {
//        let formatter = DateFormatter()
//        //formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
//        formatter.dateFormat = "HH:mm, dd.MM.yyyy"
//        let date = formatter.string(from: Date())
//        let message = text ?? ""
//        let name = isUser ? "Пользователь" : "Бот"
//        let text = "[\(date)] \(name): \(message)"
//        return text
//    }
    
    @objc func showPopup() {
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
