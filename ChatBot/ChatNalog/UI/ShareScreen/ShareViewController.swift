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
    
    private let eventLogger: FirebaseEventManager = .shared
    
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
        eventLogger.logEvent(input: .init(.share(.copy)))

        UIPasteboard.general.string = prepareText()
        moveOut()
        
        showAlert(title: nil, message: "Сообщение скопировано")
    }
    
    @IBAction private func shareButtonTapped(_ sender: Any) {
        eventLogger.logEvent(input: .init(.share(.share)))

        share()
        moveOut()
    }
}

private extension ShareViewController {
    func setup() {
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.08)
        setupBlurEffectView()
        
        eventLogger.logEvent(input: .init(.share(.open)))
    }
    
    func setupBlurEffectView() {
        blurEffectView.alpha = 0.65
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(blurTapped))
        blurEffectView.addGestureRecognizer(tap)
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
    }
    
    func prepareText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, dd.MM.yyyy"
        let date = formatter.string(from: Date())
        let message = shareText ?? ""
        
        if message.isEmpty {
            return ""
        } else {
            return "[\(date)]: \(message)"
        }
    }
    
    // MARK: - Actions
    @objc func blurTapped() {
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
        
        var attributedString = NSMutableAttributedString(string: shareText ?? " ")
        
        let sentenses = shareText?.split(separator: "\n")
        if let sentenses = sentenses, sentenses.count > 1 {
            let first = String(sentenses.first ?? "")
            let subtitle = shareText?.replacingOccurrences(of: first, with: "")
            attributedString = NSMutableAttributedString(string: first)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 1), range: NSMakeRange(0, attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .bold), range: NSMakeRange(0, attributedString.length))
            let secondAttributedString = NSMutableAttributedString(string: subtitle ?? "")
            secondAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .bold), range: NSMakeRange(0, secondAttributedString.length))
            secondAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .regular), range: NSMakeRange(0, secondAttributedString.length))
            attributedString.append(secondAttributedString)
        } else {
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 0.2235294118, green: 0.2470588235, blue: 0.3098039216, alpha: 1), range: NSMakeRange(0, attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.fontTo(.brandFontRegular, size: 16, weight: .regular), range: NSMakeRange(0, attributedString.length))
        }
        
        textView.text = shareText
        textView.attributedText = attributedString
        
        view.layoutIfNeeded()
        
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
