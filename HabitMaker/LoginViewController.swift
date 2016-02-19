//
//  ViewController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/7/16.
//  Copyright (c) 2016 SarahHowe. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK -- Outlets
    
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    //MARK -- Variables
    
    var appDelegate: AppDelegate!
    var session: NSURLSession!
    
    //var tapRecognizer: UITapGestureRecognizer? = nil
    
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
    
    
    //MARK -- Actions
    
    @IBAction func loginToHabitica(sender: UIButton)
    {
        HabiticaClient.sharedInstance.getTasks(uuidTextField.text!, apiKey: apiKeyTextField.text!) { message, error in
            
            if let error = error
            {
                print("Login failed: \(message)")
                
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                print("Login Description \(failureString)")
            }
            else
            {
                print("Login Complete! \(message)")
            }
        }
    }
}

