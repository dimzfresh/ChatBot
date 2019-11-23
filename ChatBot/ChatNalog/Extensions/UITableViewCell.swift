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
    
//    func registerCellClass(_ cellClass: AnyClass) {
//        let identifier = String.className(cellClass)
//        self.register(cellClass, forCellReuseIdentifier: identifier)
//    }
//
//    func registerCellNib(_ cellClass: AnyClass) {
//        let identifier = String.className(cellClass)
//        let nib = UINib(nibName: identifier, bundle: nil)
//        self.register(nib, forCellReuseIdentifier: identifier)
//    }
//
//    func registerHeaderFooterViewClass(_ viewClass: AnyClass) {
//        let identifier = String.className(viewClass)
//        self.register(viewClass, forHeaderFooterViewReuseIdentifier: identifier)
//    }
//
//    func registerHeaderFooterViewNib(_ viewClass: AnyClass) {
//        let identifier = String.className(viewClass)
//        let nib = UINib(nibName: identifier, bundle: nil)
//        self.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
//    }
}
