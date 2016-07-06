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
    
    //useful variables
    var tasksDownloading = false
    
    var uuid = ""
    var apiKey = ""
    
    override init()
    {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //MARK -- Get Task
    
    func taskForGetMethod(method: String, uuid: String, apiKey: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method
        //print("attempting to request the following url: \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "GET"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        
        //make the request
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error)
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
    
    //MARK -- Put Task
    
    func taskForPutMethod(method: String, uuid: String, apiKey: String, idForTaskToUpdate: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method + idForTaskToUpdate
        //print("attempting to request the following url: \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "PUT"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do
        {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        }
        catch let error as NSError
        {
            print("Habitica Client Put Method HTTP Body error: \(error.description)")
            request.HTTPBody = nil
            completionHandler(result: nil, error: error)
        }
        
        //make the request
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error)
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
    
    //MARK -- Post Task
    
    func taskForPostMethod(method: String, uuid: String, apiKey: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method
        //print("attempting to request the following url: \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do
        {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        }
        catch let error as NSError
        {
            completionHandler(result: nil, error: error)
            print("Habitica Client Post Method HTTP Body error: \(error.description)")
            request.HTTPBody = nil
        }
        
        //make the request
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error)
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
    
    //MARK -- Delete Task
    
    func taskForDeleteMethod(method: String, uuid: String, apiKey: String, idForTaskToUpdate: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method + idForTaskToUpdate
        //print("attempting to request the following url: \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "DELETE"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        
        //make the request
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error)
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
    class func errorForData(data: NSData?, jsonData: AnyObject?, response: NSURLResponse?, error: NSError?) -> NSError
    {
        if let error = error
        {
            return error
        }
        else if let jsonData = jsonData
        {
            return HabiticaClient.errorFromParsedJsonError(jsonData)
        }
        else if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject]
        {
            return HabiticaClient.errorFromParsedJsonError(parsedResult)
        }
        else
        {
            return NSError(domain: "Habitica Client Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error in errorForData"])
        }
    }
    
    class func errorFromParsedJsonError(jsonData: AnyObject) -> NSError
    {
        if let errorMessage = jsonData[HabiticaClient.JSONResponseKeys.MESSAGE] as? String
        {
            let userInfo = [NSLocalizedDescriptionKey : errorMessage]
            
            if let errorCode = jsonData[HabiticaClient.JSONResponseKeys.CODE] as? Int
            {
                return NSError(domain: "Habitica Error in Parsed Result", code: errorCode, userInfo: userInfo)
            }
            
            return NSError(domain: "Habitica Error in Parsed Result", code: 0, userInfo: userInfo)
        }
        return NSError(domain: "Habitica Error in Parsed Result", code: 0, userInfo: [NSLocalizedDescriptionKey : "Erroneous parsed result with no official message occurred"])
    }
    
    //Given raw JSON, return a useable Foundation object
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void)
    {
        //jsonString = NSString(data: data, encoding: NSUTF8StringEncoding)
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
                let newError = errorForData(data, jsonData: nil, response: nil, error: nil)
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
