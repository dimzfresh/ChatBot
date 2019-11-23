//
//  UIViewController+Alert.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
import Foundation

extension NSObject {
    static var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
}

extension UIViewController {
    class func instanceController<T>(storyboard: Storyboards) -> T {
        return storyboard.instance.instantiateViewController(withIdentifier: self.nameOfClass) as! T
    }
}

extension UIViewController {
    
    private var bigScreens: [Model] {
        return [.iPhoneX, .iPhone11, .iPhoneXR,
                .iPhoneXS, .iPhoneXSMax, .iPhone11Pro,
                .iPhone11ProMax]
    }
    
    var offset: CGFloat {
        get {
            if bigScreens.contains(UIDevice.current.type) {
                return 110
            } else {
                return 100
            }
        }
    }
    
    var isModal: Bool {
        return presentingViewController != nil
    }
    
    //@available(*, deprecated)
    func showAlert(title: String?, message: String, dismiss: Bool = false) {
   
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: { (action: UIAlertAction!) in
            
            if dismiss {
                if self.isModal {
                    self.dismiss(animated: true)
                } else {
                    //guard let viewControllers = self.navigationController?.viewControllers else { return }
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func addNavigationButton(title: String? = nil, image: UIImage? = nil, tintColor: UIColor = .white, isLeft: Bool = true, selector: Selector, font: UIFont? = nil) {
        
        let button = UIButton(type: .system)
        let originalImage = image
        button.setImage(originalImage, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: button.imageEdgeInsets.top, left: button.imageEdgeInsets.left, bottom: button.imageEdgeInsets.bottom - 15, right: button.imageEdgeInsets.right)
        button.contentEdgeInsets = UIEdgeInsets(top: button.contentEdgeInsets.top, left: button.contentEdgeInsets.left, bottom: button.contentEdgeInsets.bottom + 15, right: button.contentEdgeInsets.right + 15)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        button.sizeToFit()
        button.tintColor = tintColor
        button.addTarget(self, action: selector, for: .touchUpInside)
        
        if isLeft {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    }
    
    func showExitAlert(title: String = "", actionTitles: [String] = [], message: String = "") {
        guard actionTitles.count == 2 else { return }
        
        let firstTitle = actionTitles.first ?? ""
        let lastTitle = actionTitles.last ?? ""

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: firstTitle, style: .default, handler: { (action: UIAlertAction!) in
            
            Settings.storage.removeAuth()    
            //AppCoordinator().start()
        }))
        
        if !lastTitle.isEmpty {
            alert.addAction(UIAlertAction(title: lastTitle, style: .cancel, handler: { _ in
                
            }))
        }

        present(alert, animated: true)
    }
    
    @objc func removeSubview() {
        guard let viewWithTag = UIApplication.shared.keyWindow?.viewWithTag(100) else { return }
        viewWithTag.removeFromSuperview()
    }
    
}

extension UINavigationController {
    func pushWithFade(_ viewController: UIViewController) {
        let transition: CATransition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.fade
        view.layer.add(transition, forKey: nil)
        pushViewController(viewController, animated: false)
    }
}
