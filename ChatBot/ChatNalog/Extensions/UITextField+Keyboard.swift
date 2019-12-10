//
//  UITextField+Keyboard.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 10/12/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import UIKit

extension UITextField: DoneButton { }
extension UITextView: DoneButton { }

protocol DoneButton {
    func addDoneButtonOnKeyboard()
    func dismissKeyboard()
}

private extension DoneButton {
     func doneToolbar() -> UIToolbar {
        let doneToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(UIInputViewController.dismissKeyboard))
        done.tintColor = .brandColor
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        return doneToolbar
    }
}

extension DoneButton where Self: UITextField {
    func addDoneButtonOnKeyboard() {
        inputAccessoryView = doneToolbar()
    }
    
    private func dismissKey() {
        resignFirstResponder()
    }
    
    func setCursorPosition(location: Int) {
        if let newPosition = position(from: beginningOfDocument, offset: location) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}

extension DoneButton where Self: UITextView {
    func addDoneButtonOnKeyboard() {
        inputAccessoryView = doneToolbar()
    }
    
    private func dismissKey() {
        resignFirstResponder()
    }
    
    func setCursorPosition(location: Int) {
        if let newPosition = position(from: beginningOfDocument, offset: location) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
}

//extension UITextField {
//
//    @IBInspectable var doneAccessory: Bool {
//        get {
//            return self.doneAccessory
//        }
//        set (hasDone) {
//            if hasDone {
//                addDoneButtonOnKeyboard()
//            }
//        }
//    }
//
//    func addDoneButtonOnKeyboard() {
//        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
//        doneToolbar.barStyle = .default
//
//        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let done: UIBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneButtonAction))
//
//        let items = [flexSpace, done]
//        doneToolbar.items = items
//        doneToolbar.sizeToFit()
//
//        inputAccessoryView = doneToolbar
//    }
//
//    @objc
//    private func doneButtonAction() {
//        resignFirstResponder()
//    }
//}
