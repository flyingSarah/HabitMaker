//
//  TaskTableCell.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/2/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import UIKit

class TaskTableCell: UITableViewCell {
    
    //MARK -- Outlets
    
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var textField: UILabel!
    @IBOutlet weak var checklistStatusLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //MARK -- Useful Variables
    
    var repeatingTask: RepeatingTask? = nil
    
    var presentEditViewHandler: ((_ task: RepeatingTask) -> Void)?
    var alertErrorHandler: ((_ title: String, _ message: String) -> Void)?
    
    //MARK -- Actions

    @IBAction func checkBoxButtonPressed(_ sender: UIButton)
    {
        activityIndicator.startAnimating()
        
        if let task = repeatingTask
        {
            //we're going to prep a dictionary to act as the json body of a Habitica PUT task
            var updatesToSend = [String: AnyObject]()
            
            if(task.completed || (!task.completed && !task.isDaily && task.numRepeats == task.numFinRepeats))
            {
                //task.completed = false
                if(task.numRepeats.intValue > 0)
                {
                    //if the task has a checklist, make a new checklist array with the new correct number of tasks checked
                    updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = RepeatingTask.makeChecklistArray(task.numRepeats.intValue, numFinRepeats: task.numFinRepeats.intValue-1) as AnyObject
                }
                
                updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = false as AnyObject
            }
            else
            {
                //task.completed = true
                checkBox.imageView?.image = UIImage(named: "checkedIcon")
                
                if(task.numRepeats.intValue > 0)
                {
                    //task.numFinRepeats = task.numFinRepeats.integerValue + 1
                    
                    //if the task has a checklist, make a new checklist array with the new correct number of tasks checked
                    updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = RepeatingTask.makeChecklistArray(task.numRepeats.intValue, numFinRepeats: task.numFinRepeats.intValue+1) as AnyObject
                    
                    if(task.numRepeats.intValue == task.numFinRepeats.intValue+1)
                    {
                        //if all of the checklist tasks are done, set the full task's completed parameter to true...
                        if(task.isDaily)
                        {
                            updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true as AnyObject
                        }
                        else //...weekly tasks should only be set as complete on sundays (so habitica's scoring policy can work correctly)
                        {
                            let today = Date()
                            let weekday = weekdayFromDate(today)
                            
                            if(weekday == HabiticaClient.RepeatWeekdayKeys.SUN)
                            {
                                updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true as AnyObject
                            }
                        }
                    }
                }
                else
                {
                    //if there are no repeating tasks, just set the completed parameter to true
                    updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true as AnyObject
                }
            }
            
            //send the updates to Habitica
            HabiticaClient.sharedInstance.updateExistingTask(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey, taskID: task.id!, jsonBody: updatesToSend) { result, error in
                
                if let error = error
                {
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                    }
                    
                    let failureString = error.localizedDescription
                    self.alertErrorHandler?("Update CheckBox State Error", failureString)
                }
                else
                {
                    if let newTaskData = result as? [String: AnyObject]
                    {
                        task.completed = newTaskData[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
                        task.numRepeats = NSNumber(value: newTaskData[RepeatingTask.Keys.NUM_REPEATS] as! Int)
                        task.numFinRepeats = NSNumber(value: newTaskData[RepeatingTask.Keys.NUM_FIN_REPEATS] as! Int)
                        
                        //save the context after the response from habitica is successful
                        DispatchQueue.main.async {
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                            
                            self.activityIndicator.stopAnimating()
                        }
                    }
                    else
                    {
                        self.alertErrorHandler?("Update CheckBox State Error", "couldn't convert result to dictionary")
                    }
                    
                }
            }
        }
        else
        {
            print("clicked checkbox for item with no assigned task -- shouldn't really be possible")
        }
    }
    
    
    @IBAction func editButtonClicked(_ sender: UIButton)
    {
        presentEditViewHandler?(repeatingTask!)
    }
    
    @IBAction func deleteButtonClicked(_ sender: UIButton)
    {
        activityIndicator.startAnimating()
        
        if let task = repeatingTask
        {
            HabiticaClient.sharedInstance.deleteTask(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey, taskId: task.id!) { error in
                
                if let error = error
                {
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                    }
                    
                    let failureString = error.localizedDescription
                    self.alertErrorHandler?("Delete Task Error", failureString)
                }
                else
                {
                    DispatchQueue.main.async {
                        
                        CoreDataStackManager.sharedInstance().managedObjectContext.delete(task)
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    
    //MARK -- Helper Functions
    
    func weekdayFromDate(_ date: Date) -> String
    {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.weekday, from: date)
        let weekdayNum = components.weekday
        
        switch weekdayNum
        {
        case 1?:
            return HabiticaClient.RepeatWeekdayKeys.SUN
        case 2?:
            return HabiticaClient.RepeatWeekdayKeys.MON
        case 3?:
            return HabiticaClient.RepeatWeekdayKeys.TUES
        case 4?:
            return HabiticaClient.RepeatWeekdayKeys.WED
        case 5?:
            return HabiticaClient.RepeatWeekdayKeys.THURS
        case 6?:
            return HabiticaClient.RepeatWeekdayKeys.FRI
        case 7?:
            return HabiticaClient.RepeatWeekdayKeys.SAT
        default:
            print("Task cell's weekdayFromDate func returned default - shouldn't be possible")
            return "err"
        }
    }
}
