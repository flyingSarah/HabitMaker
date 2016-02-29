//
//  HabiticaClient.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/17/16.
//  Copyright (c) 2016 SarahHowe. All rights reserved.
//

import Foundation
import UIKit

class HabiticaClient : NSObject {
    
    static let sharedInstance = HabiticaClient()
    
    //shared session
    var session: NSURLSession
    
    //shared task arrays
    var dailyTasks = NSSet()
    var weeklyTasks = NSSet()
    
    override init()
    {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //MARK -- Get
    func taskForGetMethod(method: String, uuid: String, apiKey: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method
        print("attempting to request the following url: \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        //var jsonifyError: NSError? = nil
        
        request.HTTPMethod = "GET"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        
        //make the request
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            }
            else
            {
                HabiticaClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        return task
    }
    
    //MARK -- Helpers
    
    //given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError?) -> NSError
    {
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject]
        {
            if let errorMessage = parsedResult[HabiticaClient.JSONResponseKeys.ERROR_MESSAGE] as? String
            {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                if let errorCode = parsedResult[HabiticaClient.JSONResponseKeys.CODE] as? Int
                {
                    return NSError(domain: "Habitica Parse Error", code: errorCode, userInfo: userInfo)
                }
                
                return NSError(domain: "Habitica Parse Error", code: 0, userInfo: userInfo)
            }
        }
        
        return error!
    }
    
    //Given raw JSON, return a useable Foundation object
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void)
    {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        
        do
        {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        }
        catch let error as NSError
        {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError
        {
            completionHandler(result: nil, error: error)
        }
        else
        {
            if let _ = parsedResult?.valueForKey(HabiticaClient.JSONResponseKeys.CODE) as? String
            {
                let newError = errorForData(data, response: nil, error: nil)
                completionHandler(result: nil, error: newError)
            }
            else
            {
                completionHandler(result: parsedResult, error: nil)
            }
        }
    }
    
    //given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(parameters: [String : AnyObject]) -> String
    {
        let queryItems = parameters.map { NSURLQueryItem(name: $0, value: $1 as? String) }
        let components = NSURLComponents()
        
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
}
