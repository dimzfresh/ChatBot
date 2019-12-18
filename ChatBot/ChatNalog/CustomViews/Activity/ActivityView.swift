//
//  ActivityView.swift
//  ChatBot
//
//  Created by iOS dev on 13/10/2019.
//  Copyright © 2019 kvantsoft All rights reserved.
//

import UIKit
import NVActivityIndicatorView

final class ActivityView: UIView {
    
    private var activityIndicator: NVActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    func startLoading() {
        isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        isHidden = true
        activityIndicator.stopAnimating()
    }
}

private extension ActivityView {
    func setup() {
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        isHidden = true
        
        activityIndicator = NVActivityIndicatorView(frame: .zero, type: .ballSpinFadeLoader, color: UIColor.brandColor.withAlphaComponent(0.7), padding: 0.0)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        activityIndicator.widthAnchor.constraint(equalToConstant: 70.0).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 70.0).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30).isActive = true
    }
}
