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
    
    func getTasks(uuid: String, apiKey: String, completionHandler: (result: NSDictionary?, error: NSError?) -> Void)
    {
        taskForGetMethod(HabiticaClient.Methods.GET_TASKS, uuid: uuid, apiKey: apiKey) { JSONResult , error in
        
            if let error = error
            {
                completionHandler(result: nil, error: error)
            }
            else
            {
                print(" task for get method results: \(JSONResult)")
            }
        }
    }
}