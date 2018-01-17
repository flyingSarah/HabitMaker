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
    var session: URLSession
    
    //useful variables
    var tasksDownloading = false
    
    var uuid = ""
    var apiKey = ""
    
    override init()
    {
        session = URLSession.shared
        super.init()
    }
    
    //MARK -- Get Task
    
    func taskForGetMethod(_ method: String, uuid: String, apiKey: String, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method
        //print("attempting to request the following url: \(urlString)")
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: { (data, response, downloadError) in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                HabiticaClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 
        
        task.resume()
        return task
    }
    
    //MARK -- Put Task
    
    func taskForPutMethod(_ method: String, uuid: String, apiKey: String, idForTaskToUpdate: String, jsonBody: [String: AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method + idForTaskToUpdate
        //print("attempting to request the following url: \(urlString)")
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "PUT"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do
        {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        }
        catch let error as NSError
        {
            print("Habitica Client Put Method HTTP Body error: \(error.description)")
            request.httpBody = nil
            completionHandler(nil, error)
        }
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                HabiticaClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 
        
        task.resume()
        return task
    }
    
    //MARK -- Post Task
    
    func taskForPostMethod(_ method: String, uuid: String, apiKey: String, jsonBody: [String: AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method
        //print("attempting to request the following url: \(urlString)")
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do
        {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        }
        catch let error as NSError
        {
            completionHandler(nil, error)
            print("Habitica Client Post Method HTTP Body error: \(error.description)")
            request.httpBody = nil
        }
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                HabiticaClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 
        
        task.resume()
        return task
    }
    
    //MARK -- Delete Task
    
    func taskForDeleteMethod(_ method: String, uuid: String, apiKey: String, idForTaskToUpdate: String, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask
    {
        //build the URL and configure the request
        let urlString = HabiticaClient.Constants.BASE_URL + method + idForTaskToUpdate
        //print("attempting to request the following url: \(urlString)")
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        request.addValue(uuid, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_USER)
        request.addValue(apiKey, forHTTPHeaderField: HabiticaClient.HeaderArgumentKeys.API_KEY)
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            //parse and use the data
            if let error = downloadError
            {
                let newError = HabiticaClient.errorForData(data, jsonData: nil, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                HabiticaClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 
        
        task.resume()
        return task
    }
    
    
    //MARK -- Helpers
    
    //given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(_ data: Data?, jsonData: AnyObject?, response: URLResponse?, error: NSError?) -> NSError
    {
        if let error = error
        {
            return error
        }
        else if let jsonData = jsonData
        {
            return HabiticaClient.errorFromParsedJsonError(jsonData)
        }
        else if let parsedResult = (try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String : AnyObject]
        {
            return HabiticaClient.errorFromParsedJsonError(parsedResult as AnyObject)
        }
        else
        {
            return NSError(domain: "Habitica Client Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error in errorForData"])
        }
    }
    
    class func errorFromParsedJsonError(_ jsonData: AnyObject) -> NSError
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
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void)
    {
        //jsonString = NSString(data: data, encoding: NSUTF8StringEncoding)
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        
        do
        {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
        }
        catch let error as NSError
        {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError
        {
            completionHandler(nil, error)
        }
        else
        {
            if let _ = parsedResult?.value(forKey: HabiticaClient.JSONResponseKeys.CODE) as? String
            {
                let newError = errorForData(data, jsonData: nil, response: nil, error: nil)
                completionHandler(nil, newError)
            }
            else
            {
                completionHandler(parsedResult, nil)
            }
        }
    }
    
    //given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String
    {
        let queryItems = parameters.map { URLQueryItem(name: $0, value: $1 as? String) }
        var components = URLComponents()
        
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
}
