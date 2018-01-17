//
//  RepeatingTask.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/27/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation
import CoreData

class RepeatingTask : NSManagedObject {
    
    struct Keys
    {
        static let NUM_REPEATS = "numRepeats"
        static let NUM_FIN_REPEATS = "numFinRepeats"
        static let IS_DAILY = "isDaily"
    }
    
    @NSManaged var id: String?
    @NSManaged var text: String
    @NSManaged var isDaily: Bool
    @NSManaged var notes: String
    @NSManaged var priority: Double
    @NSManaged var completed: Bool
    @NSManaged var numRepeats: NSNumber
    @NSManaged var numFinRepeats: NSNumber
    @NSManaged var streak: NSNumber
    
    static var stopActivityIndicator: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertInto: context)
    }
    
    init(repeatingTask: [String : AnyObject], context: NSManagedObjectContext)
    {
        // Get the entity associated with the "Location" type.
        let entity =  NSEntityDescription.entity(forEntityName: "RepeatingTask", in: context)!
        
        super.init(entity: entity,insertInto: context)
        
        id = repeatingTask[HabiticaClient.TaskSchemaKeys.ID] as? String
        text = repeatingTask[HabiticaClient.TaskSchemaKeys.TEXT] as! String
        isDaily = repeatingTask[Keys.IS_DAILY] as! Bool
        notes = repeatingTask[HabiticaClient.TaskSchemaKeys.NOTES] as! String
        priority = repeatingTask[HabiticaClient.TaskSchemaKeys.PRIORITY] as! Double
        completed = repeatingTask[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool
        numRepeats = repeatingTask[Keys.NUM_REPEATS] as! NSNumber
        numFinRepeats = repeatingTask[Keys.NUM_FIN_REPEATS] as! NSNumber
        streak = repeatingTask[HabiticaClient.TaskSchemaKeys.STREAK] as! NSNumber
    }
    
    
    //MARK -- Helpers - reformat tasks from results to the RepeatingTask model
    
    static func makeTasksFromResults(_ tasks: [[String: AnyObject]])
    {
        for task in tasks
        {
            if let useableTask = returnSingleTaskFromResults(task)
            {
                DispatchQueue.main.async {
                    
                    //create the repeating task for each of the chosen tasks
                    let _ = RepeatingTask(repeatingTask: useableTask, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                }
            }
        }
        
        stopActivityIndicator?()
    }
    
    static func returnSingleTaskFromResults(_ task: [String: AnyObject]) -> [String: AnyObject]?
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
                            var sundayRepeat = false
                            for day in weekRepeatArray
                            {
                                if(day.1)
                                {
                                    countDaysToRepeat += 1
                                    if(day.0 == HabiticaClient.RepeatWeekdayKeys.SUN)
                                    {
                                        sundayRepeat = true
                                    }
                                }
                            }
                            
                            if let habiticaChecklist = task[HabiticaClient.TaskSchemaKeys.CHECKLIST] as? [[String : AnyObject]]
                            {
                                var countChecklistItems = 0
                                
                                for _ in habiticaChecklist
                                {
                                    countChecklistItems += 1
                                }
                                
                                //to be considered a weekly task, the task must meet these requirements:
                                if(countDaysToRepeat == 1 && sundayRepeat && countChecklistItems > 0)
                                {
                                    //create a dictionary that corresponds to the format of the RepeatingTask managed object
                                    let adjustedTask: [String: AnyObject] = getAdjustedTaskFromResults(task, isDaily: false)
                                    
                                    return adjustedTask
                                    
                                }
                                else if(countDaysToRepeat == 7)  //to be considered a daily task, the task must meet these requirements
                                {
                                    let adjustedTask: [String: AnyObject] = getAdjustedTaskFromResults(task, isDaily: true)
                                    
                                    return adjustedTask
                                }
                            }
                            else
                            {
                                print("from task results: couldn't find 'checklist' in task")
                            }
                        }
                        else
                        {
                            print("from task results: couldn't find 'repeat' in task")
                        }
                    }
                }
                else
                {
                    print("from task results: couldn't find 'frequency' in task")
                }
            }
        }
        else
        {
            print("from task results: couldn't find 'type' in task")
        }
        
        return nil
    }
    
    static func getAdjustedTaskFromResults(_ taskArray: [String: AnyObject], isDaily: Bool) -> [String: AnyObject]
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
                    countItemsInChecklist += 1
                    
                    if(completed)
                    {
                        countItemsCompletedInChecklist += 1
                    }
                }
                else
                {
                    print("getting adjusted results: couldn't find 'completed' items in task checklist")
                }
            }
        }
        else
        {
            print("getting adjusted results: couldn't find 'checklist' in task - setting numRepeats to 0")
        }
        
        //create a dictionary that corresponds to the format of the RepeatingTask managed object
        let adjustedTask: [String: AnyObject] = [
            HabiticaClient.TaskSchemaKeys.ID: taskArray[HabiticaClient.TaskSchemaKeys.ID] as! String as AnyObject,
            HabiticaClient.TaskSchemaKeys.TEXT: taskArray[HabiticaClient.TaskSchemaKeys.TEXT] as! String as AnyObject,
            Keys.IS_DAILY: isDaily as AnyObject,
            HabiticaClient.TaskSchemaKeys.NOTES: taskArray[HabiticaClient.TaskSchemaKeys.NOTES]!,
            HabiticaClient.TaskSchemaKeys.PRIORITY: taskArray[HabiticaClient.TaskSchemaKeys.PRIORITY] as! Double as AnyObject,
            HabiticaClient.TaskSchemaKeys.COMPLETED: taskArray[HabiticaClient.TaskSchemaKeys.COMPLETED] as! Bool as AnyObject,
            Keys.NUM_REPEATS: countItemsInChecklist as AnyObject,
            Keys.NUM_FIN_REPEATS: countItemsCompletedInChecklist as AnyObject,
            HabiticaClient.TaskSchemaKeys.STREAK: taskArray[HabiticaClient.TaskSchemaKeys.STREAK] as! Int as AnyObject
            //Keys.DATE_CHECKLIST_COMPLETED: dateChecklistCompleted
        ]

        return adjustedTask
    }
    
    //MARK -- Helpers - reformat tasks from model to habitica task schema

    static func makeChecklistArray(_ numRepeats: Int, numFinRepeats: Int) -> [[String: AnyObject]]
    {
        var checklistArray = [[String: AnyObject]]()
        
        var itr = 0
        
        while(numRepeats > itr)
        {
            var itemDict = [String: AnyObject]()
            
            if(numFinRepeats > itr)
            {
                itemDict[HabiticaClient.ChecklistBodyKeys.COMPLETED] = true as AnyObject
            }
            else
            {
                itemDict[HabiticaClient.ChecklistBodyKeys.COMPLETED] = false as AnyObject
            }
            
            itr += 1
            
            itemDict[HabiticaClient.ChecklistBodyKeys.TEXT] = "\(itr)" as AnyObject
            
            checklistArray.append(itemDict)
        }
        
        return checklistArray
    }
}

