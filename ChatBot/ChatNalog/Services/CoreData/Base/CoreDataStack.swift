//
//  CoreDataStack.swift
//  ChatBot
//
//  Created by Dmitrii Ziablikov on 18/12/2019.
//  Copyright © 2019 di. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataStackProtocol {
    var errorHandler: ((Error) -> Void)? { get set }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
    func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}

final class CoreDataStack: CoreDataStackProtocol {

    private let entityName: String

    var errorHandler: ((Error) -> Void)?

    init(name nameOfEntity: String = "Messages") {
        self.entityName = nameOfEntity
    }
    //private init() {}
    //static let shared = CoreDataManager()

    private lazy var managedContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()

    private lazy var persistentContainer: NSPersistentContainer = {
        let name = "ChatMessages"
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores { [weak self] description, error in
            if let error = error as NSError? {
                //fatalError("Unresolved error \(error), \(error.userInfo)")
                self?.errorHandler?(error)
            }
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
        }

        return container
    }()

    private lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

//    lazy var fetchedResultsController: NSFetchedResultsController<TestItems> = {
//        let fetchRequest = TestItems.createFetchRequest()
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "testKey", ascending: true)]
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
//        return fetchedResultsController
//    }()

    func saveContext() {
        guard managedContext.hasChanges else { return }

        do {
            try managedContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        managedContext.perform {
            block(self.managedContext)
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
