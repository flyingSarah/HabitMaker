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
        static let BASE_URL : String = "https://habitica.com/api/v2/"
    }
    
    //MARK -- Methods
    struct Methods
    {
        static let GET_TASKS : String = "user/tasks/"
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
        //errors
        static let CODE = "code"
        static let ERROR_MESSAGE = "err"
    }
}