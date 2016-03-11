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
    @IBOutlet weak var dragButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    //MARK -- Useful Variables
    
    var repeatingTask: RepeatingTask? = nil
    
    var presentEditViewHandler: ((task: RepeatingTask) -> Void)?
    
    //MARK -- Actions

    @IBAction func checkBoxButtonPressed(sender: UIButton)
    {
        if let task = repeatingTask
        {
            //we're going to prep a dictionary to act as the json body of a Habitica PUT task
            var updatesToSend = [String: AnyObject]()
            
            if(task.completed || (!task.completed && !task.isDaily && task.numRepeats == task.numFinRepeats))
            {
                //task.completed = false
                if(task.numRepeats.integerValue > 0)
                {
                    //if the task has a checklist, make a new checklist array with the new correct number of tasks checked
                    updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = makeChecklistArray(task.numRepeats.integerValue, numFinRepeats: task.numFinRepeats.integerValue-1)
                }
                
                updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = false
            }
            else
            {
                //task.completed = true
                checkBox.imageView?.image = UIImage(named: "checkedIcon")
                
                if(task.numRepeats.integerValue > 0)
                {
                    //task.numFinRepeats = task.numFinRepeats.integerValue + 1
                    
                    //if the task has a checklist, make a new checklist array with the new correct number of tasks checked
                    updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = makeChecklistArray(task.numRepeats.integerValue, numFinRepeats: task.numFinRepeats.integerValue+1)
                    
                    if(task.numRepeats.integerValue == task.numFinRepeats.integerValue+1)
                    {
                        //if all of the checklist tasks are done, set the full task's completed parameter to true...
                        if(task.isDaily)
                        {
                            updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true
                        }
                        else //...weekly tasks should only be set as complete on sundays (so habitica's scoring policy can work correctly)
                        {
                            let today = NSDate()
                            let weekday = weekdayFromDate(today)
                            
                            if(weekday == HabiticaClient.RepeatWeekdayKeys.SUN)
                            {
                                updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true
                            }
                        }
                    }
                }
                else
                {
                    //if there are no repeating tasks, just set the completed parameter to true
                    updatesToSend[HabiticaClient.TaskSchemaKeys.COMPLETED] = true
                }
            }
            
            //send the updates to Habitica
            let uuid = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.UUID) as! String
            let apiKey = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.ApiKey) as! String
            
            HabiticaClient.sharedInstance.updateExistingTask(uuid, apiKey: apiKey, taskID: task.id!, jsonBody: updatesToSend) { result, error in
                
                if let error = error
                {
                    let failureString = error.localizedDescription
                    print("Update CheckBox State Error: \(failureString)")
                }
                else
                {
                    if let newTaskData = result as? [String: AnyObject]
                    {
                        task.completed = newTaskData[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
                        task.numRepeats = newTaskData[RepeatingTask.Keys.NUM_REPEATS] as! Int
                        task.numFinRepeats = newTaskData[RepeatingTask.Keys.NUM_FIN_REPEATS] as! Int
                        
                        //save the context after the response from habitica is successful
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                    else
                    {
                        print("Update CheckBox State Error: couldn't convert result to dictionary")
                    }
                    
                }
            }
        }
        else
        {
            print("clicked checkbox for item with no assigned task -- shouldn't really be possible")
        }
    }
    
    
    @IBAction func editButtonClicked(sender: UIButton)
    {
        presentEditViewHandler?(task: repeatingTask!)
    }
    
    //MARK -- Helper Functions
    
    /*func isTimeToCheckOffWeeklyTask(taskLastUpdated: NSDate) -> Bool
    {
        let today = NSDate()
        
        //get the number of days in between the
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day], fromDate: taskLastUpdated, toDate: today, options: [])
        let numDaysSinceChecklistCompleted = components.day
        
        let todaysWeekday = weekdayFromDate(today)
        
    }*/
    
    func makeChecklistArray(numRepeats: Int, numFinRepeats: Int) -> [[String: AnyObject]]
    {
        var checklistArray = [[String: AnyObject]]()
        
        var itr = 0
        
        while(numRepeats > itr)
        {
            var itemDict = [String: AnyObject]()
            
            if(numFinRepeats > itr)
            {
                itemDict[HabiticaClient.ChecklistBodyKeys.COMPLETED] = true
            }
            else
            {
                itemDict[HabiticaClient.ChecklistBodyKeys.COMPLETED] = false
            }
            
            itr++
            
            itemDict[HabiticaClient.ChecklistBodyKeys.TEXT] = "\(itr)"
            
            checklistArray.append(itemDict)
        }
        
        return checklistArray
    }
    
    func weekdayFromDate(date: NSDate) -> String
    {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.Weekday, fromDate: date)
        let weekdayNum = components.weekday
        
        switch weekdayNum
        {
        case 1:
            return HabiticaClient.RepeatWeekdayKeys.SUN
        case 2:
            return HabiticaClient.RepeatWeekdayKeys.MON
        case 3:
            return HabiticaClient.RepeatWeekdayKeys.TUES
        case 4:
            return HabiticaClient.RepeatWeekdayKeys.WED
        case 5:
            return HabiticaClient.RepeatWeekdayKeys.THURS
        case 6:
            return HabiticaClient.RepeatWeekdayKeys.FRI
        case 7:
            return HabiticaClient.RepeatWeekdayKeys.SAT
        default:
            print("Task cell's weekdayFromDate func returned default - shouldn't be possible")
            return "err"
        }
    }
}
