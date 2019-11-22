//
//  BaseViewModel.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 13/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit

protocol BindableType: AnyObject {
    associatedtype ViewModelType

    var viewModel: ViewModelType! { get set }

    func bindViewModel()
}

extension BindableType where Self: UIViewController {
    func bind(to model: Self.ViewModelType) {
        viewModel = model
        loadViewIfNeeded()
        bindViewModel()
    }
}

extension BindableType where Self: UITableViewCell {
    func bind(to model: Self.ViewModelType) {
        viewModel = model
        bindViewModel()
    }
}

extension BindableType where Self: UICollectionViewCell {
    func bind(to model: Self.ViewModelType) {
        viewModel = model
        bindViewModel()
    }
}


protocol BaseViewModel {
    associatedtype Service
    init(service: Service?)
}

//protocol BaseViewModelOutput: class {
//    func startLoading()
//    func stopLoading()
//}
//
//extension BaseViewModelOutput where Self: UIViewController {
//    func startLoading() {
//        DispatchQueue.main.async { self.start() }
//    }
//    
//    func stopLoading() {
//        DispatchQueue.main.async { self.stop() }
//    }
//}
//
//private extension BaseViewModelOutput where Self: UIViewController {
//    func start() {
//        let activityView = ActivityView()
//        activityView.frame = view.bounds
//        activityView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(activityView)
//        activityView.startLoading()
//        view.isUserInteractionEnabled = false
//    }
//    
//    func stop() {
//        guard let activityView = view.subviews.first(where: { $0 is ActivityView }) as? ActivityView else { return }
//        activityView.stopLoading()
//        activityView.removeFromSuperview()
//        view.isUserInteractionEnabled = true
//    }
//    
//    func showAlert(text: String, completion: (() -> Void)? = nil) {
//        let alert = UIAlertController(title: "", message: text, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) in
//            completion?()
//        }))
//        
//        present(alert, animated: true)
//    }
//}
