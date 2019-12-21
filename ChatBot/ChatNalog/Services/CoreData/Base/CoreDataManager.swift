//
//  CoreDataManager.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 19/12/2019.
//  Copyright © 2019 kvantsoft. All rights reserved.
//

import Foundation

enum Result<T>{
    case success(T)
    case failure(Error)
}

enum CoreDataError: Error {
    case cannotFetch(String)
    case cannotSave(Error)
}

protocol CoreDataManagerProtocol {
    func fetch<Entity: ManagedObjectConvertible>
        (with predicate: NSPredicate?,
         sortDescriptors: [NSSortDescriptor]?,
         fetchLimit: Int?,
         completion: @escaping (Result<[Entity]>) -> Void)
    func save<Entity: ManagedObjectConvertible>
        (entities: [Entity],
         completion: @escaping (Error?) -> Void)
}
extension CoreDataManagerProtocol {
    func fetch<Entity: ManagedObjectConvertible>
        (with predicate: NSPredicate? = nil,
         sortDescriptors: [NSSortDescriptor]? = nil,
         fetchLimit: Int? = nil,
         completion: @escaping (Result<[Entity]>) -> Void) {
        
        fetch(with: predicate,
            sortDescriptors: sortDescriptors,
            fetchLimit: fetchLimit,
            completion: completion)
    }
}

final class CoreDataManager: CoreDataManagerProtocol {

    let coreData: CoreDataStackProtocol

    init(coreData: CoreDataStackProtocol = CoreDataStack()) {
        self.coreData = coreData
    }

    func fetch<Entity : ManagedObjectConvertible>(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, fetchLimit: Int?, completion: @escaping (Result<[Entity]>) -> Void) {
        
        coreData.performForegroundTask { context in
            do {
                let fetchRequest = Entity.ManagedObject.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.sortDescriptors = sortDescriptors
                if let fetchLimit = fetchLimit {
                    fetchRequest.fetchLimit = fetchLimit
                }
                let results = try context.fetch(fetchRequest) as? [Entity.ManagedObject]
                let items: [Entity] = results?.compactMap { $0.toEntity() as? Entity } ?? []
                completion(.success(items))
            } catch {
                let fetchError = CoreDataError.cannotFetch("Cannot fetch error: \(error))")
                completion(.failure(fetchError))
            }
        }
    }

    func save<Entity: ManagedObjectConvertible>(entities: [Entity], completion: @escaping (Error?) -> Void) {
        coreData.performBackgroundTask { context in
            _ = entities.compactMap { entity -> Entity.ManagedObject? in
                return entity.toManagedObject(in: context)
            }
            do {
                try context.save()
                completion(nil)
            } catch {
                completion(CoreDataError.cannotSave(error))
            }
        }
    }
}
