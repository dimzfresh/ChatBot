//
//  AnimatedButton.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 26/11/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit

final class AnimatedButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            let transform: CGAffineTransform = isHighlighted ? .init(scaleX: 0.9, y: 0.9) : .identity
            animate(transform)
        }
    }
}

private extension AnimatedButton {
    func animate(_ transform: CGAffineTransform) {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 3,
            options: [.curveEaseInOut],
            animations: {
                self.transform = transform
        })
    }
}
