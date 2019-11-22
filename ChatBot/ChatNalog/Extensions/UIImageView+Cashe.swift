//
//  UIImageView+Cashe.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit
//import AlamofireImage
//import Alamofire
//
//let imageCache = AutoPurgingImageCache()
//
//extension UIImageView {
//    func download(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit, isCatalog: Bool = false, placeholder: UIImage? = nil, needAuth: Bool = false) {
//
//        start()
//
//        guard let url = URL(string: "\(MemesBackend.host)\(link)") else {
//            stop()
//            return
//        }
//
//        download(url: url, contentMode: mode, isCatalog: isCatalog, placeholder: placeholder)
//    }
//
//    func cancelRequest() {
//        stop()
//        af_cancelImageRequest()
//        layer.removeAllAnimations()
//        image = nil
//    }
//}
//
//private extension UIImageView {
//    func download(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit, isCatalog: Bool = false, placeholder: UIImage? = nil) {
//        let urlString = url.path
//
//        if let cached = imageCache.image(withIdentifier: urlString) {
//            stop()
//            image = cached
//            return
//        }
//
//        af_setImage(withURL: url, placeholderImage: placeholder, imageTransition: .crossDissolve(0.2)) { result in
//
//            self.stop()
//            guard
//                let mimeType = result.response?.mimeType, mimeType.hasPrefix("image"),
//                let data = result.data,
//                let image = UIImage(data: data)
//                else {
//                    DispatchQueue.main.async { self.image = nil }
//                    return }
//
//            DispatchQueue.main.async {
//                imageCache.add(image, withIdentifier: urlString)
//                self.image = image
//            }
//        }
//    }
//
//    func start() {
//        let activities = subviews.filter { $0.isKind(of: UIActivityIndicatorView.self) }
//        let superActivities = superview?.subviews.filter { $0.isKind(of: UIActivityIndicatorView.self) }
//        guard activities.isEmpty, superActivities?.isEmpty ?? true else { return }
//
//        let activity = UIActivityIndicatorView(style: .white)
//        activity.color = .brandYellow
//        activity.startAnimating()
//        addSubview(activity)
//        activity.center = center
//    }
//
//    func stop() {
//        subviews.forEach {
//            if let activity = $0 as? UIActivityIndicatorView {
//                activity.stopAnimating()
//            }
//        }
//    }
//}

