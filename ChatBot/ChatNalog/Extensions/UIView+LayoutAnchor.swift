//
//  UIView+LayoutAnchor.swift
//  ChatBot
//
//  Created by iOS dev on 06/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

enum RoundType {
    case top
    case right
    case left
    case none
    case bottom
    case both
    case rightTop
    case leftTop
}

extension UIView {
    class func loadNib<T: UIView>(_ viewType: T.Type) -> T {
        let className = String(describing: viewType)
        return Bundle(for: viewType).loadNibNamed(className, owner: nil, options: nil)!.first as! T
    }
    
    class func loadNib() -> Self {
        return loadNib(self)
    }
}

extension UIView {
    private var tapGestureRecognizer: UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        return tapGestureRecognizer
    }
    
    func dropShadow(radius: CGFloat, opacity: Float, size: CGSize, shadowRadius: CGFloat, shadowColor: UIColor) {
        layer.cornerRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowOffset = size
        layer.shadowRadius = shadowRadius
        layer.shadowColor = shadowColor.cgColor
        layer.masksToBounds = false
    }
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        if #available(iOS 11.0, *) {
            clipsToBounds = true
            layer.cornerRadius = radius
            layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
    
    func round(with type: RoundType, radius: CGFloat = 5.0) {
        var corners: UIRectCorner
        
        switch type {
        case .top:
            corners = [.topLeft, .topRight]
        case .right:
            corners = [.bottomRight, .topRight]
        case .rightTop:
            corners = [.topRight]
        case .leftTop:
            corners = [.topLeft]
        case .left:
            corners = [.bottomLeft, .topLeft]
        case .none:
            corners = []
        case .bottom:
            corners = [.bottomLeft, .bottomRight]
        case .both:
            corners = [.allCorners]
        }
        
        DispatchQueue.main.async {
            self.layer.mask = nil
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
    }
    
    func setDismissKeyboardOnTap() {
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func dismissKeyboard() {
        endEditing(true)
    }
}

// UIImage
extension UIView {
    var asImage: UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

@IBDesignable
extension UIButton {
    @IBInspectable var multipleLineMode: Bool {
        get {
            return titleLabel?.numberOfLines ?? 0 > 0
        }
        set {
            if newValue {
                titleLabel?.numberOfLines = 0
                titleLabel?.lineBreakMode = .byWordWrapping
                titleLabel?.textAlignment = .center
            } else {
                titleLabel?.numberOfLines = 1
                titleLabel?.lineBreakMode = .byTruncatingTail
            }
        }
    }

}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

// NSLayoutAnchor Helper
extension UIView {
    @discardableResult
    func topAnchor(to anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> Self {
        topAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    @discardableResult
    func leadingAnchor(to anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        leadingAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    @discardableResult
    func bottomAnchor(to anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> Self {
        bottomAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    @discardableResult
    func trailingAnchor(to anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        trailingAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    @discardableResult
    func widthAnchor(constant: CGFloat) -> Self {
        widthAnchor.constraint(equalToConstant: constant).isActive = true
        return self
    }
    @discardableResult
    func heightAnchor(constant: CGFloat) -> Self {
        heightAnchor.constraint(equalToConstant: constant).isActive = true
        return self
    }
    @discardableResult
    func dimensionAnchors(width widthConstant: CGFloat, height heightConstant: CGFloat) -> Self {
        widthAnchor.constraint(equalToConstant: widthConstant).isActive = true
        heightAnchor.constraint(equalToConstant: heightConstant).isActive = true
        return self
    }
    @discardableResult
    func dimensionAnchors(size: CGSize) -> Self {
        widthAnchor.constraint(equalToConstant: size.width).isActive = true
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
        return self
    }
    @discardableResult
    func centerYAnchor(to anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0)  -> Self {
        centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    @discardableResult
    func centerXAnchor(to anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0)  -> Self {
        centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }
    
    func activateAnchors() {
        translatesAutoresizingMaskIntoConstraints = false
    }
}


