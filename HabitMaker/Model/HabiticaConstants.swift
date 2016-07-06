//
//  HabiticaConstants.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/17/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation

extension HabiticaClient {
    
    //MARK -- Constants
    struct Constants
    {
        //URLs
        static let BASE_URL : String = "https://habitica.com/api/v3/"
        static let TASKS_USER_METHOD : String = "tasks/user/" //for getting all tasks and creating a new task
        static let TASKS_METHOD : String = "tasks/" //for deleting and updating tasks
    }
    
    //MARK -- Header Argument Keys
    struct HeaderArgumentKeys
    {
        static let API_KEY = "x-api-key"
        static let API_USER = "x-api-user"
    }
    
    //MARK -- Task Schema Keys
    struct TaskSchemaKeys
    {
        static let ID = "id"
        static let TEXT = "text"
        static let TYPE = "type"
        static let COMPLETED = "completed"
        static let REPEAT = "repeat"
        static let CHECKLIST = "checklist"
        static let PRIORITY = "priority"
        static let NOTES = "notes"
        static let STREAK = "streak"
        static let FREQUENCY = "frequency"
    }
    
    struct RepeatWeekdayKeys {
        static let MON = "m"
        static let TUES = "t"
        static let WED = "w"
        static let THURS = "th"
        static let FRI = "f"
        static let SAT = "s"
        static let SUN = "su"
    }
    
    struct ChecklistBodyKeys {
        static let TEXT = "text"
        static let COMPLETED = "completed"
    }
    
    //MARK -- JSON Response Keys
    struct JSONResponseKeys
    {
        static let DATA = "data"
        
        //errors
        static let CODE = "success"
        static let ERROR = "error"
        static let MESSAGE = "message"
    }
    
    //MARK -- Keys for User Defaults
    struct UserDefaultKeys
    {
        static let UUID = "uuid"
        static let ApiKey = "apiKey"
        static let UserLoginAvailable = "userLoginAvailable"
    }
}