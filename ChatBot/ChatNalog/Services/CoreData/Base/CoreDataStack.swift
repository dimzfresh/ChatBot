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

//extension CoreDataStack {
//
//    //MARK: - Save
//    func save() {
//
//        guard let entity = NSEntityDescription.entity(forEntityName: entityName,
//                                                      in: managedContext) else { return }
//
//        guard let message = NSManagedObject(entity: entity,
//                                            insertInto: managedContext) else { return }
//
//
//
//
//    }
//
//    //MARK: - Fetch
//
//    func fetch() -> [NSManagedObject]? {
////        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName!)
////        do{
////            return (try (managedContext.fetch(fetchRequest) as? [NSManagedObject]))!
////        } catch let error as NSError{
////           print("Could not fetch. \(error), \(error.userInfo)")
//           return nil
////        }
//    }
//
//    //MARK: DROP DATA
//
//    func drop() {
//
////        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName!)
////        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
////        do {
////            try managedContext.execute(batchDeleteRequest)
////            self.save()
////            Alerts.displayAlertMessage(messageToDisplay: "Data Dropped")
////
////        } catch let error as NSError {
////            print("Could not fetch. \(error), \(error.userInfo)")
////        }
//    }
//
//    //MARK: - Delete
//
//    func delete(at index: Int?) {
//
////        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName!)
////
////        do {
////            entities=try managedContext.fetch(fetchRequest) as! [NSManagedObject]
////
////                managedContext.delete(entities[index!])
////                self.save()
////                entities.remove(at: index!)
////                Alerts.displayAlertMessage(messageToDisplay: "Data Deleted")
////
////        } catch let error as NSError {
////            print("Could not fetch. \(error), \(error.userInfo)")
////        }
////        return entities
//    }
//
//    //MARK: - Update
//    func update(at index: Int, mobile:String) {
//
////            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName!)
////
////            do {
////                entities=try managedContext.fetch(fetchRequest) as! [NSManagedObject]
////                self.save()
////
////                entities[index!].setValue(mobile, forKey: "mobile") //setting value for a key (attribute) at an index.
////
////            } catch let error as NSError {
////                print("Could not fetch. \(error), \(error.userInfo)")
////            }
////            return entities
//    }
//}
