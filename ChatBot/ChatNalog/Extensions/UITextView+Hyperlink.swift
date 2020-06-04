//
//  UITextView+Hyperlink.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 04.06.2020.
//  Copyright © 2020 kvantsoft. All rights reserved.
//

import UIKit

extension UITextView {
    func hyperLink(attributedOriginalText: NSMutableAttributedString, hyperLink: String, urlString: String) {
        
        //let attributedOriginalText = NSMutableAttributedString(string: originalText)
        let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
        //let fullRange = NSMakeRange(0, attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: linkRange)

        linkTextAttributes = [
            kCTForegroundColorAttributeName: UIColor.blue,
            kCTUnderlineStyleAttributeName: NSUnderlineStyle.single.rawValue,
            ] as [NSAttributedString.Key : Any]
        
        attributedText = attributedOriginalText
    }
    
}
