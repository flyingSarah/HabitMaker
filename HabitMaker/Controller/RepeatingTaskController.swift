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
    
    let redTaskColor = UIColor(red: 0.996, green: 0.388, blue: 0.412, alpha: 0.5)
    let yellowTaskColor = UIColor(red: 1.0, green: 1.0, blue: 0.2, alpha: 0.5)
    let greenTaskColor = UIColor(red: 0.18, green: 0.722, blue: 0.18, alpha: 0.5)
    let blueTaskColor = UIColor(red: 0.314, green: 0.714, blue: 0.902, alpha: 0.5)
    
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.plain, target: self, action: #selector(RepeatingTaskController.logout(_:)))
        
        let refreshButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(RepeatingTaskController.refreshButtonClicked(_:)))
        let addButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(RepeatingTaskController.addTaskButtonClicked(_:)))
        
        let buttons = [refreshButton, addButton]
        
        navigationItem.rightBarButtonItems = buttons
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //set the completion behavior for when the tasks finish downloading
        RepeatingTask.stopActivityIndicator = { [unowned self] () -> Void in
            
            self.stopActivityIndicator()
        }
        
        //start the activity indicator animating if the tasks are currently downloading
        if(HabiticaClient.sharedInstance.tasksDownloading)
        {
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
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        RepeatingTask.stopActivityIndicator = nil
    }
    
    //MARK -- Navigation Bar Actions
    
    @objc func logout(_ sender: AnyObject)
    {
        CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
        
        UserDefaults.standard.setValue("", forKey: HabiticaClient.UserDefaultKeys.UUID)
        HabiticaClient.sharedInstance.uuid = ""
        UserDefaults.standard.setValue("", forKey: HabiticaClient.UserDefaultKeys.ApiKey)
        HabiticaClient.sharedInstance.apiKey = ""
        UserDefaults.standard.set(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func refreshButtonClicked(_ sender: AnyObject)
    {
        DispatchQueue.main.async {
            
            self.activityIndicator.startAnimating()
        }
        
        //delete fetched results
        let fetchedObjects = fetchedResultsController.fetchedObjects
        
        for object in fetchedObjects!
        {
            let task = object as! RepeatingTask
            CoreDataStackManager.sharedInstance().managedObjectContext.delete(task)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        //delete the rest of the items (the ones from the other task list)
        CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
        
        //get all the tasks
        HabiticaClient.sharedInstance.getTasks(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey) { error in
            
            if let error = error
            {
                DispatchQueue.main.async {
                    
                    self.activityIndicator.stopAnimating()
                }
                
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                self.showAlertController("Error Refreshing Tasks", message: failureString)
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            }
        }
    }
    
    @objc func addTaskButtonClicked(_ sender: AnyObject)
    {
        DispatchQueue.main.async(execute: {
            
            let controller = self.storyboard!.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
            
            controller.isDaily = self.isDailyView
            
            
            self.navigationController?.pushViewController(controller, animated: true)
        })
    }
    
    //MARK -- Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RepeatingTask")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: HabiticaClient.TaskSchemaKeys.PRIORITY, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isDaily == %@", NSNumber(value: self.isDailyView as Bool))
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    
    //MARK -- Table Behavior
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let task = fetchedResultsController.object(at: indexPath) as! RepeatingTask
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableCell") as! TaskTableCell
        
        DispatchQueue.main.async {
            
            self.configureCell(cell, withTask: task)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if(indexPath == tableView.indexPathsForVisibleRows?.last)
        {
            if(activityIndicator.isAnimating)
            {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let task = fetchedResultsController.object(at: indexPath) as! RepeatingTask
        
        showAlertController(task.text, message: task.notes)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        switch (editingStyle)
        {
        case .delete:
            //here we get the task, then delete it from core data
            let task = fetchedResultsController.object(at: indexPath) as! RepeatingTask
            sharedContext.delete(task)
            CoreDataStackManager.sharedInstance().saveContext()
        default:
            break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        switch type
        {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! TaskTableCell
            let task = controller.object(at: indexPath!) as! RepeatingTask
            configureCell(cell, withTask: task)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        tableView.endUpdates()
    }
    
    //MARK -- Configure Cell
    
    func configureCell(_ cell: TaskTableCell, withTask task: RepeatingTask)
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
        let today = Date()
        let todaysWeekday = cell.weekdayFromDate(today)
        
        if(!task.isDaily && !task.completed && task.numRepeats == task.numFinRepeats && todaysWeekday == HabiticaClient.RepeatWeekdayKeys.SUN)
        {
            cell.activityIndicator.startAnimating()
            
            HabiticaClient.sharedInstance.updateExistingTask(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey, taskID: task.id!, jsonBody: [HabiticaClient.TaskSchemaKeys.COMPLETED: true as AnyObject]) { result, error in
                
                if let error = error
                {
                    DispatchQueue.main.async {
                        
                        cell.activityIndicator.stopAnimating()
                    }
                    
                    let failureString = error.localizedDescription
                    self.showAlertController("Configure Cell Error", message: failureString)
                }
                else
                {
                    if let newTaskData = result as? [String: AnyObject]
                    {
                        task.completed = newTaskData[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
                        
                        //save the context after the response from habitica is successful
                        DispatchQueue.main.async {
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                    else
                    {
                        
                        self.showAlertController("Configure Cell Error", message: "couldn't convert result to dictionary")
                    }
                    
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                    }
                    
                }
            }
        }
        
        cell.textField.text = task.text
        
        if(task.numRepeats.intValue > 1)
        {
            cell.checklistStatusLabel.isHidden = false
            cell.checklistStatusLabel.text = "\(task.numFinRepeats)/\(task.numRepeats)"
        }
        else
        {
            cell.checklistStatusLabel.isHidden = true
        }
        
        //set the background color based on priority
        switch task.priority
        {
        case 1.0:
            cell.backgroundColor = greenTaskColor
        case 1.5:
            cell.backgroundColor = yellowTaskColor
        case 2.0:
            cell.backgroundColor = redTaskColor
        default:
            cell.backgroundColor = blueTaskColor
        }
        
        //set the completion handler for the cell's "presentEditViewHanlder" so that clicking on the edit button will take you to the edit view
        cell.presentEditViewHandler = { [unowned self] (task: RepeatingTask) -> Void in
            
            DispatchQueue.main.async {
                
                let controller = self.storyboard!.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
                controller.task = task
                controller.isDaily = task.isDaily
                
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
        //set the completion handler for the cell's "alertErrorHandler" so when errors occur within the cell, the alert controller will show
        cell.alertErrorHandler = { [unowned self] (title: String, message: String) -> Void in
            
            self.showAlertController(title, message: message)
        }
    }
    
    //MARK -- Helper Functions
    
    func stopActivityIndicator()
    {
        DispatchQueue.main.async {
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    func showAlertController(_ title: String, message: String)
    {
        DispatchQueue.main.async {
            
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}
