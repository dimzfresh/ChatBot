//
//  ShareViewController.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 23/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import UIKit

protocol ShareViewProtocol {
    var shareText: String? { get set }
}

final class ShareViewController: UIViewController, ShareViewProtocol {
    
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        return blurEffectView
    }()
    
    var shareText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        moveIn()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
        let heightOfText = sizeThatFitsTextView.height
        textViewHeightConstraint.constant = heightOfText
    }
    
    @IBAction private func copyButtonTapped(_ sender: Any) {
        UIPasteboard.general.string = shareText ?? ""
        moveOut()
    }
    
    @IBAction private func shareButtonTapped(_ sender: Any) {
        share()
        moveOut()
    }
}

private extension ShareViewController {
    func setup() {
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.05)
        setupBlurEffectView()
    }
    
    func setupBlurEffectView() {
        blurEffectView.alpha = 0.6
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(blurTapped))
        blurEffectView.addGestureRecognizer(tap)
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
    }
    
    // MARK: - Actions
    @objc
    func blurTapped() {
        moveOut()
    }
    
    func share() {
        let root = UIApplication.shared.windows.first?.rootViewController
        let activityVC = UIActivityViewController(activityItems: [shareText ?? ""] as [Any], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad, let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = root?.view
            popoverController.permittedArrowDirections = .down
        } else {
            activityVC.navigationController?.navigationBar.tintColor = .lightGray
        }
        root?.present(activityVC, animated: true)
    }
    
    func moveIn() {
        view.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
        view.alpha = 0
        textView.text = shareText
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.view.alpha = 1
        }) { _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    func moveOut() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.view.alpha = 0.0
        }) { _ in
            self.sendResetFlagNotification()
            self.view.removeFromSuperview()
        }
    }
    
    func sendResetFlagNotification() {
        NotificationCenter.default.post(name: .resetPopupFlag, object: nil, userInfo: nil)
    }
}
