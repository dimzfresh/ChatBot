//
//  AnimationsFactory.swift
//  ChatBot
//
//  Created by iOS dev on 30/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

final class AnimationsFactory {
    static func animateScale(for view: UIButton, image: UIImage? = nil) {
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
            view.setImage(image, for: .normal)
        }) { _ in
            
            view.transform = .init(scaleX: 0.9, y: 0.9)
            
            UIView.animate(withDuration: 1.0,
                                       delay: 0,
                                       usingSpringWithDamping: 0.2,
                                       initialSpringVelocity: 5,
                                       options: [.autoreverse, .curveLinear,
                                                 .repeat, .allowUserInteraction],
                                       animations: {
                                        view.transform = .identity
            })
        }
    }    
}
