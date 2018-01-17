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
    
    func getTasks(_ uuid: String, apiKey: String, completionHandler: @escaping (_ error: NSError?) -> Void)
    {
        tasksDownloading = true
        
        taskForGetMethod(HabiticaClient.Constants.TASKS_USER_METHOD, uuid: uuid, apiKey: apiKey) { JSONResult, error in
        
            if let error = error
            {
                self.tasksDownloading = false
                completionHandler(error)
            }
            else
            {
                if let dataArray = JSONResult as? [String: AnyObject]
                {
                    if let taskArray = dataArray[JSONResponseKeys.DATA] as? [[String : AnyObject]]
                    {
                        if(taskArray.count > 0)
                        {
                            //print("Successuflly found \(taskArray.count) total tasks from Habitica")
                            
                            RepeatingTask.makeTasksFromResults(taskArray)
                            
                            self.tasksDownloading = false
                            
                            completionHandler(nil)
                        }
                    }
                    else
                    {
                        let newError = HabiticaClient.errorForData(nil, jsonData: JSONResult, response: nil, error: error)
                        completionHandler(newError)
                    }
                }
                else
                {
                    completionHandler(NSError(domain: "getTasks parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "no data array in task results"]))
                }
            }
        }
    }
    
    func updateExistingTask(_ uuid: String, apiKey: String, taskID: String, jsonBody: [String: AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
    {
        taskForPutMethod(HabiticaClient.Constants.TASKS_METHOD, uuid: uuid, apiKey: apiKey, idForTaskToUpdate: taskID, jsonBody: jsonBody) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(nil, error)
            }
            else
            {
                if let taskData = JSONResult as? [String: AnyObject]
                {
                    if let task = taskData[JSONResponseKeys.DATA] as? [String: AnyObject]
                    {
                        if let reformattedTask = RepeatingTask.returnSingleTaskFromResults(task)
                        {
                            completionHandler(reformattedTask as AnyObject, nil)
                        }
                    }
                    else
                    {
                        let newError = HabiticaClient.errorForData(nil, jsonData: JSONResult, response: nil, error: error)
                        completionHandler(nil, newError)
                    }
                }
                else
                {
                    completionHandler(nil, NSError(domain: "updateExistingTask parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "no data array in task results"]))
                }
            }
        }
    }
    
    func createNewTask(_ uuid: String, apiKey: String, jsonBody: [String: AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
    {
        taskForPostMethod(HabiticaClient.Constants.TASKS_USER_METHOD, uuid: uuid, apiKey: apiKey, jsonBody: jsonBody) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(nil, error)
            }
            else
            {
                if let taskData = JSONResult as? [String: AnyObject]
                {
                    if let task = taskData[JSONResponseKeys.DATA] as? [String: AnyObject]
                    {
                        if let reformattedTask = RepeatingTask.returnSingleTaskFromResults(task)
                        {
                            completionHandler(reformattedTask as AnyObject, nil)
                        }
                    }
                    else
                    {
                        let newError = HabiticaClient.errorForData(nil, jsonData: JSONResult, response: nil, error: error)
                        completionHandler(nil, newError)
                    }
                }
                else
                {
                    completionHandler(nil, NSError(domain: "updateExistingTask parse error", code: 0, userInfo: [NSLocalizedDescriptionKey: "no data array in task results"]))
                }
            }
        }
    }
    
    func deleteTask(_ uuid: String, apiKey: String, taskId: String, completionHandler: @escaping (_ error: NSError?) -> Void)
    {
        taskForDeleteMethod(HabiticaClient.Constants.TASKS_METHOD, uuid: uuid, apiKey: apiKey, idForTaskToUpdate: taskId) { JSONResult, error in
            
            if let error = error
            {
                completionHandler(error)
            }
            else
            {
                completionHandler(nil)
            }
        }
    }
}
