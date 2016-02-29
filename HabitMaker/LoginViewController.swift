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
    
    var appDelegate: AppDelegate!
    var session: NSURLSession!
    
    var currentUUID: String? = nil
    var currentApiKey: String? = nil
    
    //var tapRecognizer: UITapGestureRecognizer? = nil
    
    //MARK -- Keys for UserDefaults
    
    struct UserDefaultKeys
    {
        static let UUID = "uuid"
        static let ApiKey = "apiKey"
        static let UserLoginAvailable = "userLoginAvailable"
    }
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //get the shared url session
        session = NSURLSession.sharedSession()
        
        uuidTextField.delegate = self
        apiKeyTextField.delegate = self
        
        //set placeholder text color
        //Found out how to do this from this stackoverflow topic: http://stackoverflow.com/questions/26076054/changing-placeholder-text-color-with-swift
        uuidTextField.attributedPlaceholder = NSAttributedString(string: "UUID", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
        apiKeyTextField.attributedPlaceholder = NSAttributedString(string: "API Key", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
        
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
        let userLoginAvailable = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultKeys.UserLoginAvailable)
        
        if(userLoginAvailable)
        {
            print("a user login is available")
            currentUUID = NSUserDefaults.standardUserDefaults().valueForKey(UserDefaultKeys.UUID) as? String
            uuidTextField.text = currentUUID!
            currentApiKey = NSUserDefaults.standardUserDefaults().valueForKey(UserDefaultKeys.ApiKey) as? String
            apiKeyTextField.text = currentApiKey!
        }
        
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        uuidTextField.text = ""
        apiKeyTextField.text = ""
        //loginButton.enabled = false
    }

    /*override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }*/
    
    //MARK -- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK -- Actions
    
    @IBAction func loginButtonPressed(sender: UIButton)
    {
        HabiticaClient.sharedInstance.getTasks(uuidTextField.text!, apiKey: apiKeyTextField.text!) { dailyTasks, weeklyTasks, error in
            
            if let error = error
            {
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                print("Login Description \(failureString)")
            }
            else
            {
                print("Login Complete!")
                NSUserDefaults.standardUserDefaults().setValue(self.uuidTextField.text, forKey: UserDefaultKeys.UUID)
                self.currentUUID = self.uuidTextField.text
                NSUserDefaults.standardUserDefaults().setValue(self.apiKeyTextField.text, forKey: UserDefaultKeys.ApiKey)
                self.currentApiKey = self.apiKeyTextField.text
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultKeys.UserLoginAvailable)
                self.loginToHabitica(dailyTasks!, weeklyTasks: weeklyTasks!)
            }
        }
    }
    
    func loginToHabitica(dailyTasks: NSSet, weeklyTasks: NSSet)
    {
        
    }
}

