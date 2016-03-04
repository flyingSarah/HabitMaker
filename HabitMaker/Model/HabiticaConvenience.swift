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
                    
                    if(taskArray.count > 0)
                    {
                        print("Successuflly found \(taskArray.count) total tasks from Habitica")
                        
                        let dailyTasks = DailyTask.dailyTasksFromResults(taskArray)
                        let weeklyTasks = WeeklyTask.weeklyTasksFromResults(taskArray)
                        
                        //print("\n\ndaily tasks:\n\n\(dailyTasks)\n\n")
                        HabiticaClient.sharedInstance.dailyTasks = dailyTasks
                        HabiticaClient.sharedInstance.weeklyTasks = weeklyTasks
                        completionHandler(dailyTasks: dailyTasks, weeklyTasks: weeklyTasks, error: nil)
                    }
                }
                else
                {
                    print("task parse error: task results were nil")
                }
            }
        }
    }
}