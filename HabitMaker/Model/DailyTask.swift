//
//  RepeatingTask.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/27/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation
import CoreData

class DailyTask : NSManagedObject {
    
    struct Keys
    {
        static let NUM_REPEATS = "numRepeats"
        static let NUM_FIN_REPEATS = "numFinRepeats"
    }
    
    @NSManaged var id: String?
    @NSManaged var text: String
    @NSManaged var notes: String
    @NSManaged var priority: Double
    @NSManaged var completed: Bool
    @NSManaged var numRepeats: NSNumber
    @NSManaged var numFinRepeats: NSNumber
    @NSManaged var streak: NSNumber
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dailyTask: [String : AnyObject], context: NSManagedObjectContext)
    {
        // Get the entity associated with the "Location" type.
        let entity =  NSEntityDescription.entityForName("DailyTask", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        id = dailyTask[HabiticaClient.TaskSchemaKeys.ID] as? String
        text = dailyTask[HabiticaClient.TaskSchemaKeys.TEXT] as! String
        notes = dailyTask[HabiticaClient.TaskSchemaKeys.NOTES] as! String
        priority = dailyTask[HabiticaClient.TaskSchemaKeys.PRIORITY] as! Double
        completed = dailyTask[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
        numRepeats = dailyTask[Keys.NUM_REPEATS] as! NSNumber
        numFinRepeats = dailyTask[Keys.NUM_FIN_REPEATS] as! NSNumber
        streak = dailyTask[HabiticaClient.TaskSchemaKeys.STREAK] as! NSNumber
    }
    
    
    //MARK -- Helpers - reformat tasks from results to model
    
    static func dailyTasksFromResults(tasks: [[String: AnyObject]]) -> NSSet
    {
        var dailyTasks = NSSet()
        
        for task in tasks
        {
            if let habiticaType = task[HabiticaClient.TaskSchemaKeys.TYPE] as? String
            {
                if(habiticaType == "daily")
                {
                    if let habiticaFreq = task[HabiticaClient.TaskSchemaKeys.FREQUENCY] as? String
                    {
                        if(habiticaFreq == "weekly")
                        {
                            if let weekRepeatArray = task[HabiticaClient.TaskSchemaKeys.REPEAT] as? [String : Bool]
                            {
                                var countDaysToRepeat = 0
                                for day in weekRepeatArray
                                {
                                    if(day.1)
                                    {
                                        countDaysToRepeat++
                                    }
                                }
                                
                                if(countDaysToRepeat == 7)
                                {
                                    //create a dictionary that corresponds to the format of the RepeatingTask managed object
                                    let adjustedTask: [String: AnyObject] = getAdjustedTaskFromResults(task)
                                    
                                    //create the RepeatingTask and add it to an array of daily tasks
                                    dispatch_async(dispatch_get_main_queue()) {
                                        
                                        dailyTasks = dailyTasks.setByAddingObject(DailyTask(dailyTask: adjustedTask, context: CoreDataStackManager.sharedInstance().managedObjectContext))
                                    }
                                }
                            }
                            else
                            {
                                print("from dailyTask results: couldn't find 'repeat' in task")
                            }
                        }
                    }
                    else
                    {
                        print("from dailyTask results: couldn't find 'frequency' in task")
                    }
                }
            }
            else
            {
                print("from dailyTask results: couldn't find 'type' in task")
            }
        }
        
        return dailyTasks
    }
    
    static func getAdjustedTaskFromResults(taskArray: [String: AnyObject]) -> [String: AnyObject]
    {
        //count the number of checklist items and if there are any count how many of them are completed
        var countItemsInChecklist = 0
        var countItemsCompletedInChecklist = 0
        
        if let habiticaChecklist = taskArray[HabiticaClient.TaskSchemaKeys.CHECKLIST] as? [[String: AnyObject]]
        {
            for item in habiticaChecklist
            {
                if let completed = item[HabiticaClient.ChecklistBodyKeys.COMPLETED] as? Bool
                {
                    countItemsInChecklist++
                    
                    if(completed)
                    {
                        countItemsCompletedInChecklist++
                    }
                }
                else
                {
                    print("getting adjusted daily task from results: couldn't find 'completed' items in task checklist")
                }
            }
        }
        else
        {
            print("getting adjusted daily task from results: couldn't find 'checklist' in task - setting numRepeats to 0")
        }
        
        //create a dictionary that corresponds to the format of the RepeatingTask managed object
        let adjustedTask: [String: AnyObject] = [
            HabiticaClient.TaskSchemaKeys.ID: taskArray[HabiticaClient.TaskSchemaKeys.ID]!,
            HabiticaClient.TaskSchemaKeys.TEXT: taskArray[HabiticaClient.TaskSchemaKeys.TEXT]!,
            HabiticaClient.TaskSchemaKeys.NOTES: taskArray[HabiticaClient.TaskSchemaKeys.NOTES]!,
            HabiticaClient.TaskSchemaKeys.PRIORITY: taskArray[HabiticaClient.TaskSchemaKeys.PRIORITY] as! Double,
            HabiticaClient.TaskSchemaKeys.COMPLETED: taskArray[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool,
            Keys.NUM_REPEATS: countItemsInChecklist,
            Keys.NUM_FIN_REPEATS: countItemsCompletedInChecklist,
            HabiticaClient.TaskSchemaKeys.STREAK: taskArray[HabiticaClient.TaskSchemaKeys.STREAK]!
        ]
        //print(adjustedTask)
        return adjustedTask
    }
    
    //MARK -- Helpers - reformat tasks from model to habitica task schema

}

