//
//  UITableViewCellExtension.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 06/10/2019.
//  Copyright © 2019 di. All rights reserved.
//

import UIKit

extension UITableViewCell {
    static var identifier: String { return String(describing: self.self) }

    class var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}

extension UITableView {
    func register<Cell>(
        cell: Cell.Type,
        forCellReuseIdentifier reuseIdentifier: String = Cell.identifier
        ) where Cell: UITableViewCell {
        register(cell, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeue<Cell>(_ reusableCell: Cell.Type) -> Cell? where Cell: UITableViewCell {
        return dequeueReusableCell(withIdentifier: reusableCell.identifier) as? Cell
    }
}

extension UITableViewCell {
    func copyToClipboard(text: String) {
        
        let alert = UIAlertController(title: "Скопировать сообщение?", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Скопировать", style: .default, handler: { _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = text
            
        }))
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .destructive))
        
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController?.present(alert, animated: true)
    }
}

