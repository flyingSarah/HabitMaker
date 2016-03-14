//
//  ViewController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/7/16.
//  Copyright (c) 2016 SarahHowe. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK -- Outlets
    
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    //MARK -- Variables
    
    //var appDelegate: AppDelegate!
    //var session: NSURLSession!
    
    var currentUUID: String? = nil
    var currentApiKey: String? = nil
    
    //var tapRecognizer: UITapGestureRecognizer? = nil
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //get the app delegate
        //appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //get the shared url session
        //session = NSURLSession.sharedSession()
        
        uuidTextField.delegate = self
        apiKeyTextField.delegate = self
        
        //add a little left indent/padding on the text fields
        //Found how to do this from this stackoverflow topic: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
        let uuidSpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        uuidTextField.leftViewMode = UITextFieldViewMode.Always
        uuidTextField.leftView = uuidSpacerView
        
        let apiKeySpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        apiKeyTextField.leftViewMode = UITextFieldViewMode.Always
        apiKeyTextField.leftView = apiKeySpacerView
        
        //loginButton.enabled = false
        
        //initialize tap recognizer
        
        //check to see if a login is already stored and if so, go ahead and advance to the next view
        let userLoginAvailable = NSUserDefaults.standardUserDefaults().boolForKey(HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        if(userLoginAvailable)
        {
            print("a user login is available")
            
            //sync data every time you log in by deleting the objects and then re-downloading them
            
            CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
            
            currentUUID = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.UUID) as? String
            uuidTextField.text = currentUUID!
            currentApiKey = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.ApiKey) as? String
            apiKeyTextField.text = currentApiKey!
            
            loginToHabitica(currentUUID!, apiKey: currentApiKey!)
        }
        else
        {
            uuidTextField.text = ""
            apiKeyTextField.text = ""
        }
        
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
    }
    
    //MARK -- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK -- Actions
    
    @IBAction func loginButtonPressed(sender: UIButton)
    {
        currentUUID = uuidTextField.text
        currentApiKey = apiKeyTextField.text
        
        loginToHabitica(currentUUID!, apiKey: currentApiKey!)
    }
    
    func loginToHabitica(uuid: String, apiKey: String)
    {
        HabiticaClient.sharedInstance.getTasks(uuidTextField.text!, apiKey: apiKeyTextField.text!) { error in
            
            if let error = error
            {
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                self.showAlertController("Login Error", message: failureString)
            }
            else
            {
                NSUserDefaults.standardUserDefaults().setValue(self.uuidTextField.text, forKey: HabiticaClient.UserDefaultKeys.UUID)
                NSUserDefaults.standardUserDefaults().setValue(self.apiKeyTextField.text, forKey: HabiticaClient.UserDefaultKeys.ApiKey)
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                })
                
                print("Login Complete!")
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
            
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    //MARK -- Helper Functions
    func showAlertController(title: String, message: String)
    {
        dispatch_async(dispatch_get_main_queue()) {
            
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alert.addAction(okAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

