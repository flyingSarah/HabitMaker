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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK -- Useful Variables
    var isDailyView = false
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
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
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //set the completion behavior for when the tasks finish downloading
        RepeatingTask.stopActivityIndicator = { [unowned self] () -> Void in
            
            self.stopActivityIndicator()
        }
        
        //start the activity indicator animating if the tasks are currently downloading
        if(HabiticaClient.sharedInstance.tasksDownloading)
        {
            print("start animating when view will appear")
            activityIndicator.startAnimating()
        }
        
        //fetch the tasks from the model
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch{}
        
        taskTable.reloadData()
    }
    
    //MARK -- Navigation Bar Actions
    
    func logout(sender: AnyObject)
    {
        CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
        
        NSUserDefaults.standardUserDefaults().setValue("", forKey: HabiticaClient.UserDefaultKeys.UUID)
        HabiticaClient.sharedInstance.uuid = ""
        NSUserDefaults.standardUserDefaults().setValue("", forKey: HabiticaClient.UserDefaultKeys.ApiKey)
        HabiticaClient.sharedInstance.apiKey = ""
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func refreshButtonClicked(sender: AnyObject)
    {
        dispatch_async(dispatch_get_main_queue()) {
            
            print("start animating when refresh button clicked")
            self.activityIndicator.startAnimating()
        }
        
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
        
        print("about to get all tasks from refresh with \(HabiticaClient.sharedInstance.uuid) and \(HabiticaClient.sharedInstance.apiKey)")
        
        //get all the tasks
        HabiticaClient.sharedInstance.getTasks(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey) { error in
            
            if let error = error
            {
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                self.showAlertController("Error Refreshing Tasks", message: failureString)
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            }
        }
    }
    
    func addTaskButtonClicked(sender: AnyObject)
    {
        dispatch_async(dispatch_get_main_queue(), {
            
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("EditViewController") as! EditViewController
            
            controller.isDaily = self.isDailyView
            
            
            self.navigationController?.pushViewController(controller, animated: true)
        })
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
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if(indexPath == tableView.indexPathsForVisibleRows?.last)
        {
            if(activityIndicator.isAnimating())
            {
                print("stop animaging when last cell is displayed")
                activityIndicator.stopAnimating()
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let task = fetchedResultsController.objectAtIndexPath(indexPath) as! RepeatingTask
        
        showAlertController(task.text, message: task.notes)
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
            HabiticaClient.sharedInstance.updateExistingTask(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey, taskID: task.id!, jsonBody: [HabiticaClient.TaskSchemaKeys.COMPLETED: true]) { result, error in
                
                if let error = error
                {
                    let failureString = error.localizedDescription
                    self.showAlertController("Configure Cell Error", message: failureString)
                }
                else
                {
                    if let newTaskData = result as? [String: AnyObject]
                    {
                        task.completed = newTaskData[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
                        
                        //save the context after the response from habitica is successful
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                    else
                    {
                        print("Configure Cell Error: couldn't convert result to dictionary")
                    }
                    
                }
            }
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
        
        //set the completion handler for the cell's "presentEditViewHanlder" so that clicking on the edit button will take you to the edit view
        cell.presentEditViewHandler = { [unowned self] (task: RepeatingTask) -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("EditViewController") as! EditViewController
                controller.task = task
                controller.isDaily = task.isDaily
                
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    //MARK -- Helper Functions
    
    func stopActivityIndicator()
    {
        dispatch_async(dispatch_get_main_queue()) {
            
            print("stop animating with repeat task stop func")
            self.activityIndicator.stopAnimating()
        }
    }
    
    func showAlertController(title: String, message: String)
    {
        dispatch_async(dispatch_get_main_queue()) {
            
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alert.addAction(okAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}