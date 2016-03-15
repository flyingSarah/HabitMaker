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
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
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
        
        //initialize tap recognizer
        tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
        tapRecognizer!.numberOfTapsRequired = 1
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addKeyboardDismissRecognizer()
        
        //check to see if a login is already stored and if so, go ahead and advance to the next view
        let userLoginAvailable = NSUserDefaults.standardUserDefaults().boolForKey(HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        if(userLoginAvailable)
        {
            print("a user login is available")
            
            //sync data every time you log in by deleting the objects and then re-downloading them
            CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
            
            HabiticaClient.sharedInstance.uuid = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.UUID) as! String
            uuidTextField.text = HabiticaClient.sharedInstance.uuid
            HabiticaClient.sharedInstance.apiKey = NSUserDefaults.standardUserDefaults().valueForKey(HabiticaClient.UserDefaultKeys.ApiKey) as! String
            apiKeyTextField.text = HabiticaClient.sharedInstance.apiKey
            
            loginButton.enabled = true
            
            loginToHabitica(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey)
        }
        else
        {
            print("a user login is not available")
            
            uuidTextField.text = ""
            HabiticaClient.sharedInstance.uuid = ""
            apiKeyTextField.text = ""
            HabiticaClient.sharedInstance.apiKey = ""
            
            loginButton.enabled = false
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeKeyboardDismissRecognizer()
    }
    
    //MARK -- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK -- Actions
    
    @IBAction func loginButtonPressed(sender: UIButton)
    {
        HabiticaClient.sharedInstance.uuid = uuidTextField.text!
        HabiticaClient.sharedInstance.apiKey = apiKeyTextField.text!
        
        loginToHabitica(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey)
    }
    
    @IBAction func textFieldsChanged(sender: UITextField)
    {
        if(uuidTextField.text!.isEmpty || apiKeyTextField.text!.isEmpty)
        {
            loginButton.enabled = false
        }
        else
        {
            loginButton.enabled = true
        }
    }
    
    @IBAction func signUpButtonPressed(sender: UIButton)
    {
        signUp()
    }
    
    func signUp()
    {
        let url = NSURL(string: "https://habitica.com/static/front")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    @IBAction func infoButtonPressed(sender: UIButton)
    {
        dispatch_async(dispatch_get_main_queue()) {
            
            let alert: UIAlertController = UIAlertController(title: "Login UUID and API Key...", message: "... can be found in settings/API after signing up on Habitica.com.", preferredStyle: .Alert)
            
            let closeAction: UIAlertAction = UIAlertAction(title: "Close", style: .Cancel, handler: nil)
            
            let signUpAction: UIAlertAction = UIAlertAction(title: "Sign Up", style: .Default) { _ in
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.signUp()
                }
            }
            
            let findLoginInfo: UIAlertAction = UIAlertAction(title: "Find UUID", style: .Default) { _ in
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    let url = NSURL(string: "https://habitica.com/#/options/settings/api")!
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            
            alert.addAction(closeAction)
            alert.addAction(signUpAction)
            alert.addAction(findLoginInfo)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func loginToHabitica(uuid: String, apiKey: String)
    {
        dismissAnyVisibleKeyboards()
        
        HabiticaClient.sharedInstance.getTasks(uuid, apiKey: apiKey) { error in
            
            if let error = error
            {
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                self.showAlertController("Login Error", message: failureString)
            }
            else
            {
                NSUserDefaults.standardUserDefaults().setValue(uuid, forKey: HabiticaClient.UserDefaultKeys.UUID)
                HabiticaClient.sharedInstance.uuid = uuid
                NSUserDefaults.standardUserDefaults().setValue(apiKey, forKey: HabiticaClient.UserDefaultKeys.ApiKey)
                HabiticaClient.sharedInstance.apiKey = apiKey
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    let controller = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
                    
                    self.presentViewController(controller, animated: true, completion: nil)
                }
                
                print("Login Complete!")
            }
        }
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
    
    //dismiss the keyboard
    func addKeyboardDismissRecognizer()
    {
        view.addGestureRecognizer(tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer()
    {
        view.removeGestureRecognizer(tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer)
    {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        view.endEditing(true)
        return true
    }
}

extension LoginViewController {
    
    func dismissAnyVisibleKeyboards()
    {
        if(uuidTextField.isFirstResponder() || apiKeyTextField.isFirstResponder())
        {
            view.endEditing(true)
        }
    }
}