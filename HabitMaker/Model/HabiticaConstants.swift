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
    
    //MARK -- JSON Response Keys
    struct JSONResponseKeys
    {
        //errors
        static let STATUS = "stat"
        static let CODE = "code"
        static let MESSAGE = "message"
    }
}