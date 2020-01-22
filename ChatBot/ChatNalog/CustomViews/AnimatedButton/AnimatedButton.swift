//
//  AnimatedButton.swift
//  ChatBot
//
//  Created by iOS dev on 26/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class AnimatedButton: UIButton {
//    override var isHighlighted: Bool {
//        didSet {
//            let transform: CGAffineTransform = isHighlighted ? .init(scaleX: 0.9, y: 0.9) : .identity
//            animate(transform)
//        }
//    }
}

extension AnimatedButton {
    func animate(_ callback: @escaping () -> Void) {
        //        UIView.animate(
        //            withDuration: 0.25,
        //            delay: 0,
        //            usingSpringWithDamping: 0.5,
        //            initialSpringVelocity: 3,
        //            options: [.curveEaseInOut],
        //            animations: {
        //                self.transform = transform
        //        })
        
        layer.removeAllAnimations()
        
        let transform: CGAffineTransform = .init(scaleX: 0.9, y: 0.9)
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 3,
            options: [.curveEaseInOut],
            animations: {
                self.transform = transform
        },
            completion: { _ in
                UIView.animate(withDuration: 0.15, delay: 0.05, options: .curveLinear, animations: {
                    self.transform = .identity
                }, completion: { _ in
                    callback()
                })
        })
    }
}
