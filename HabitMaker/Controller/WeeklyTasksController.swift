//
//  WeeklyTasksController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/2/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation
import UIKit

class WeeklyTasksController: UITableViewController {
    
    //MARK -- Outlets
    @IBOutlet var taskTable: UITableView!
    
    //MARK -- Useful Variables
    
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading weekly tasks...")
        
        //create the needed bar button items
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("logout:"))
        
        let refreshButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshButtonClicked:"))
        let addButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addTaskButtonClicked:"))
        
        let buttons = [refreshButton, addButton]
        
        navigationItem.rightBarButtonItems = buttons
        
        //set up tasks
        
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        taskTable.reloadData()
    }
    
    
    //MARK -- Table Behavior
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return HabiticaClient.sharedInstance.weeklyTasks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let task = HabiticaClient.sharedInstance.weeklyTasks.allObjects[indexPath.row] as! RepeatingTask
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskTableCell", forIndexPath: indexPath) as! TaskTableCell
        
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
        
        return cell
    }
}