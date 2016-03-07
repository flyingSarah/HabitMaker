//
//  RepeatingTasksController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/2/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

//import Foundation
import UIKit
import CoreData

class RepeatingTaskController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    //MARK -- Outlets
    @IBOutlet var taskTable: UITableView!
    
    //MARK -- Useful Variables
    var isDailyView = false
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading \(navigationItem.title!)...")
        
        //set which view we are controlling
        if(navigationItem.title! == "Daily Tasks")
        {
            isDailyView = true
        }
        
        //create the needed bar button items
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("logout:"))
        
        let refreshButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshButtonClicked:"))
        let addButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addTaskButtonClicked:"))
        
        let buttons = [refreshButton, addButton]
        
        navigationItem.rightBarButtonItems = buttons
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //set up tasks
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch{}
        
        fetchedResultsController.delegate = self
        
        taskTable.reloadData()
    }
    
    //MARK -- Navigation Bar Actions
    
    func logout(sender: AnyObject)
    {
        CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
        
        NSUserDefaults.standardUserDefaults().setValue("", forKey: HabiticaClient.UserDefaultKeys.UUID)
        NSUserDefaults.standardUserDefaults().setValue("", forKey: HabiticaClient.UserDefaultKeys.ApiKey)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func refreshButtonClicked(sender: AnyObject)
    {
        //delete fetched results
        let fetchedObjects = fetchedResultsController.fetchedObjects
        
        for object in fetchedObjects!
        {
            let task = object as! RepeatingTask
            CoreDataStackManager.sharedInstance().managedObjectContext.deleteObject(task)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        //delete the rest of the items (the ones from the other task list)
        CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
        
        let uuid = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.UUID) as! String
        let apiKey = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.ApiKey) as! String
        
        //get all the tasks
        HabiticaClient.sharedInstance.getTasks(uuid, apiKey: apiKey) { error in
            
            if let error = error
            {
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                print("Login Description \(failureString)")
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            }
        }
    }
    
    //MARK -- Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "RepeatingTask")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: HabiticaClient.TaskSchemaKeys.PRIORITY, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "isDaily == %@", NSNumber(bool: self.isDailyView))
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    
    //MARK -- Table Behavior
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
        //return HabiticaClient.sharedInstance.weeklyTasks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let task = fetchedResultsController.objectAtIndexPath(indexPath) as! RepeatingTask
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskTableCell") as! TaskTableCell
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.configureCell(cell, withTask: task)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        switch (editingStyle)
        {
        case .Delete:
            //here we get the task, then delete it from core data
            let task = fetchedResultsController.objectAtIndexPath(indexPath) as! RepeatingTask
            sharedContext.deleteObject(task)
            CoreDataStackManager.sharedInstance().saveContext()
        default:
            break
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type
        {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type
        {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! TaskTableCell
            let task = controller.objectAtIndexPath(indexPath!) as! RepeatingTask
            configureCell(cell, withTask: task)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        tableView.endUpdates()
    }
    
    //MARK -- Configure Cell
    
    func configureCell(cell: TaskTableCell, withTask task: RepeatingTask)
    {
        //fill in the components of the task's cell
        cell.repeatingTask = task
        
        if(task.completed || (task.numRepeats != 0 && task.numRepeats == task.numFinRepeats))
        {
            cell.checkBox.imageView?.image = UIImage(named: "checkedIcon")
        }
        else
        {
            cell.checkBox.imageView?.image = UIImage(named: "uncheckedIcon")
        }
        
        //weekly tasks need to send a task completed update to habitica if it's sunday and all the repeats items are checked off
        let today = NSDate()
        let todaysWeekday = cell.weekdayFromDate(today)
        
        if(!task.isDaily && !task.completed && task.numRepeats == task.numFinRepeats && todaysWeekday == HabiticaClient.RepeatWeekdayKeys.SUN)
        {
            print("TODO: should send update for weekly task completed parameter. set to true")
        }
        
        cell.textField.text = task.text
        
        if(task.numRepeats.integerValue > 1)
        {
            cell.checklistStatusLabel.hidden = false
            cell.checklistStatusLabel.text = "\(task.numFinRepeats)/\(task.numRepeats)"
        }
        else
        {
            cell.checklistStatusLabel.hidden = true
        }
    }
    
    //MARK -- Helper Functions
}