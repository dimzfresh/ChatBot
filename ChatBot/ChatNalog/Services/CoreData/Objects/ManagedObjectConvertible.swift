//
//  ManagedObjectConvertible.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 19/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import CoreData

protocol ManagedObjectConvertible {
    associatedtype ManagedObject: NSManagedObject, ManagedObjectProtocol
    func toManagedObject(in context: NSManagedObjectContext) -> ManagedObject?
}
