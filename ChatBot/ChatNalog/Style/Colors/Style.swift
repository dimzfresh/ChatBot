//
//  Style.swift
//  ChatBot
//
//  Created by iOS dev on 20/11/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit

extension UIColor {
    class var brandColor: UIColor {
        return #colorLiteral(red: 0.3882352941, green: 0.3176470588, blue: 0.7960784314, alpha: 1)
    }
}

extension UIFont {
    class func fontTo(_ font: UIFont, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard let customFont = UIFont(name: nameOfClass, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        if #available(iOS 11.0, *) {
            return UIFontMetrics.default.scaledFont(for: customFont)
        } else {
            return customFont
        }
        //label.adjustsFontForContentSizeCategory = true
    }
    
    class var brandFontRegular: UIFont {
        guard let customFont = UIFont(name: "Roboto", size: 16.0) else {
            return UIFont.systemFont(ofSize: 15.0, weight: .regular)
        }
        return customFont
    }
}
