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
    
    func getTasks(uuid: String, apiKey: String, completionHandler: (error: NSError?) -> Void)
    {
        tasksDownloading = true
        
        taskForGetMethod(HabiticaClient.Constants.TASK_METHODS, uuid: uuid, apiKey: apiKey) { JSONResult, error in
        
            if let error = error
            {
                self.tasksDownloading = false
                completionHandler(error: error)
            }
            else
            {
                if let taskArray = JSONResult as? [[String : AnyObject]]
                {
                    
                    if(taskArray.count > 0)
                    {
                        print("Successuflly found \(taskArray.count) total tasks from Habitica")
                        
                        RepeatingTask.makeTasksFromResults(taskArray)
                        
                        self.tasksDownloading = false
                        
                        completionHandler(error: nil)
                    }
                }
                else
                {
                    completionHandler(error: NSError(domain: "getTasks parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "task results were nil"]))
                }
            }
        }
    }
    
    func updateExistingTask(uuid: String, apiKey: String, taskID: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject?, error: NSError?) -> Void)
    {
        taskForPutMethod(HabiticaClient.Constants.TASK_METHODS, uuid: uuid, apiKey: apiKey, idForTaskToUpdate: taskID, jsonBody: jsonBody) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(result: nil, error: error)
            }
            else
            {
                if let task = JSONResult as? [String: AnyObject]
                {
                    if let reformattedTask = RepeatingTask.returnSingleTaskFromResults(task)
                    {
                        completionHandler(result: reformattedTask, error: nil)
                    }
                }
                else
                {
                    completionHandler(result: nil, error: NSError(domain: "updateExistingTask parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "task results were nil"]))
                }
            }
        }
        
        //TODO: if we are changing the completed state, I should inc or dec the score on habitica accordingly
    }
    
    func createNewTask(uuid: String, apiKey: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject?, error: NSError?) -> Void)
    {
        taskForPostMethod(HabiticaClient.Constants.TASK_METHODS, uuid: uuid, apiKey: apiKey, jsonBody: jsonBody) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(result: nil, error: error)
            }
            else
            {
                if let task = JSONResult as? [String: AnyObject]
                {
                    if let reformattedTask = RepeatingTask.returnSingleTaskFromResults(task)
                    {
                        completionHandler(result: reformattedTask, error: nil)
                    }
                    else
                    {
                        print("error reformatting new task")
                    }
                }
                else
                {
                    completionHandler(result: nil, error: NSError(domain: "createNewTask parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "task results were nil"]))
                }
            }
        }
    }
    
    func deleteTask(uuid: String, apiKey: String, taskId: String, completionHandler: (error: NSError?) -> Void)
    {
        taskForDeleteMethod(HabiticaClient.Constants.TASK_METHODS, uuid: uuid, apiKey: apiKey, idForTaskToUpdate: taskId) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(error: error)
            }
            else
            {
                completionHandler(error: nil)
            }
        }
    }
}