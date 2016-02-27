//
//  HabiticaConvenience.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/17/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import UIKit
import Foundation

extension HabiticaClient {
    
    //MARK -- Task Methods
    
    func getTasks(uuid: String, apiKey: String, completionHandler: (dailyTasks: NSSet?, weeklyTasks: NSSet?, error: NSError?) -> Void)
    {
        taskForGetMethod(HabiticaClient.Methods.GET_TASKS, uuid: uuid, apiKey: apiKey) { JSONResult , error in
        
            if let error = error
            {
                completionHandler(dailyTasks: nil, weeklyTasks: nil, error: error)
            }
            else
            {
                if let taskArray = JSONResult as? [[String : AnyObject]]
                {
                    var dailyTasks = NSSet()
                    
                    for task in taskArray
                    {
                        if let habiticaType = task["type"] as? String
                        {
                            //print("habitica type found: \(habiticaType)")
                            
                            if(habiticaType == "daily")
                            {
                                if let weekRepeatArray = task["repeat"] as? [String : Bool]
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
                                        dailyTasks = dailyTasks.setByAddingObject(task)
                                    }
                                }
                                else
                                {
                                    print("task parse error: couldn't find 'repeat' in task and convert it to [string:bool]")
                                }
                            }
                        }
                        else
                        {
                            print("task parse error: couldn't find 'type' in task")
                        }
                    }
                    
                    //print("\n\ndaily tasks:\n\n\(dailyTasks)\n\n")
                    completionHandler(dailyTasks: dailyTasks, weeklyTasks: nil, error: nil)
                }
                else
                {
                    print("task parse error: couldn't convert result to task array")
                }
            }
        }
    }
}