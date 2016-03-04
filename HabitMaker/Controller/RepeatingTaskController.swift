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
        
        //set up tasks
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch{}
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        taskTable.reloadData()
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
        
        configureCell(cell, withTask: task)
        
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
        if(task.completed)
        {
            cell.checkBox.imageView?.image = UIImage(named: "checkedIcon")
        }
        else
        {
            cell.checkBox.imageView?.image = UIImage(named: "uncheckedIcon")
        }
        
        cell.textField.text = task.text
        cell.checklistStatusLabel.text = "\(task.numFinRepeats)/\(task.numRepeats)"
    }
}