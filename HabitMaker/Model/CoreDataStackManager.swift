//
//  CoreDataStackManager.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/26/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "HabitMaker.sqlite"

class CoreDataStackManager {
    
    
    // MARK -- Shared Instance
    
    /**
    *  This class variable provides an easy way to get access
    *  to a shared instance of the CoreDataStackManager class.
    */
    class func sharedInstance() -> CoreDataStackManager
    {
        struct Static
        {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    // MARK -- The Core Data stack.
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        print("Instantiating the applicationDocumentsDirectory property")
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        
        print("Instantiating the managedObjectModel property")
        
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        print("Instantiating the persistentStoreCoordinator property")
        
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        print("sqlite path: \(url.path!)\n")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK -- Core Data Saving support
    
    func saveContext()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch let error as NSError
            {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Save Context Unresolved Error: \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    //MARK -- Core Data Deleting support
    
    //learned how to do this from this stackoverflow thread: http://stackoverflow.com/questions/1077810/delete-reset-all-entries-in-core-data/31961330#31961330
    func deleteAllItemsInContext()
    {
        //fetch all RepeatingTasks
        let fetchRequest = NSFetchRequest(entityName: "RepeatingTask")
        
        if #available(iOS 9.0, *)
        {
            print("deleting all in iOS 9.0")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            //perform the delete
            do
            {
                try persistentStoreCoordinator?.executeRequest(deleteRequest, withContext: managedObjectContext)
            }
            catch let error as NSError
            {
                NSLog("Delete Items in Context Unresolved Error: \(error), \(error.userInfo)")
                abort()
            }
        }
        else
        {
            print("deleting all in iOS < 9.0")
            // Fallback on earlier versions
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            let fetchedObjects = fetchedResultsController.fetchedObjects
            
            for object in fetchedObjects!
            {
                let task = object as! RepeatingTask
                managedObjectContext.deleteObject(task)
            }
        }
        
        saveContext()
    }
}