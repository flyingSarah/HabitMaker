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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        uuidTextField.leftViewMode = UITextFieldViewMode.always
        uuidTextField.leftView = uuidSpacerView
        
        let apiKeySpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        apiKeyTextField.leftViewMode = UITextFieldViewMode.always
        apiKeyTextField.leftView = apiKeySpacerView
        
        //initialize tap recognizer
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.handleSingleTap(_:)))
        tapRecognizer!.numberOfTapsRequired = 1
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addKeyboardDismissRecognizer()
        
        //check to see if a login is already stored and if so, go ahead and advance to the next view
        let userLoginAvailable = UserDefaults.standard.bool(forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
        
        if(userLoginAvailable)
        {
            //print("a user login is available")
            
            activityIndicator.startAnimating()
            
            //sync data every time you log in by deleting the objects and then re-downloading them
            CoreDataStackManager.sharedInstance().deleteAllItemsInContext()
            
            HabiticaClient.sharedInstance.uuid = UserDefaults.standard.value(forKey: HabiticaClient.UserDefaultKeys.UUID) as! String
            uuidTextField.text = HabiticaClient.sharedInstance.uuid
            HabiticaClient.sharedInstance.apiKey = UserDefaults.standard.value(forKey: HabiticaClient.UserDefaultKeys.ApiKey) as! String
            apiKeyTextField.text = HabiticaClient.sharedInstance.apiKey
            
            loginButton.isEnabled = true
            
            loginToHabitica(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey)
        }
        else
        {
            //print("a user login is not available")
            
            uuidTextField.text = ""
            HabiticaClient.sharedInstance.uuid = ""
            apiKeyTextField.text = ""
            HabiticaClient.sharedInstance.apiKey = ""
            
            loginButton.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeKeyboardDismissRecognizer()
    }
    
    //MARK -- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK -- Actions
    
    @IBAction func loginButtonPressed(_ sender: UIButton)
    {
        DispatchQueue.main.async {
            
            self.activityIndicator.startAnimating()
        }
        
        HabiticaClient.sharedInstance.uuid = uuidTextField.text!
        HabiticaClient.sharedInstance.apiKey = apiKeyTextField.text!
        
        loginToHabitica(HabiticaClient.sharedInstance.uuid, apiKey: HabiticaClient.sharedInstance.apiKey)
    }
    
    @IBAction func textFieldsChanged(_ sender: UITextField)
    {
        if(uuidTextField.text!.isEmpty || apiKeyTextField.text!.isEmpty)
        {
            loginButton.isEnabled = false
        }
        else
        {
            loginButton.isEnabled = true
        }
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton)
    {
        signUp()
    }
    
    func signUp()
    {
        let url = URL(string: "https://habitica.com/static/front")!
        UIApplication.shared.openURL(url)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton)
    {
        let alert: UIAlertController = UIAlertController(title: "Login UUID and API Key...", message: "... can be found in settings/API after signing up on Habitica.com.", preferredStyle: .alert)
        
        let closeAction: UIAlertAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        
        let signUpAction: UIAlertAction = UIAlertAction(title: "Sign Up", style: .default) { _ in
            
            DispatchQueue.main.async {
                
                self.signUp()
            }
        }
        
        let findLoginInfo: UIAlertAction = UIAlertAction(title: "Find UUID", style: .default) { _ in
            
            DispatchQueue.main.async {
                
                let url = URL(string: "https://habitica.com/#/options/settings/api")!
                UIApplication.shared.openURL(url)
            }
        }
        
        alert.addAction(closeAction)
        alert.addAction(signUpAction)
        alert.addAction(findLoginInfo)
        
        DispatchQueue.main.async {
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func loginToHabitica(_ uuid: String, apiKey: String)
    {
        dismissAnyVisibleKeyboards()
        
        HabiticaClient.sharedInstance.getTasks(uuid, apiKey: apiKey) { error in
            
            if let error = error
            {
                UserDefaults.standard.set(false, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                DispatchQueue.main.async {
                    
                    self.activityIndicator.stopAnimating()
                }
                
                //get the description of the specific error that results from the failed request
                let failureString = error.localizedDescription
                self.showAlertController("Login Error", message: failureString)
            }
            else
            {
                UserDefaults.standard.setValue(uuid, forKey: HabiticaClient.UserDefaultKeys.UUID)
                HabiticaClient.sharedInstance.uuid = uuid
                UserDefaults.standard.setValue(apiKey, forKey: HabiticaClient.UserDefaultKeys.ApiKey)
                HabiticaClient.sharedInstance.apiKey = apiKey
                UserDefaults.standard.set(true, forKey: HabiticaClient.UserDefaultKeys.UserLoginAvailable)
                
                DispatchQueue.main.async {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    self.activityIndicator.stopAnimating()
                    
                    let controller = self.storyboard!.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                    
                    self.present(controller, animated: true, completion: nil)
                }
                
                print("Login Complete!")
            }
        }
    }
    
    //MARK -- Helper Functions
    func showAlertController(_ title: String, message: String)
    {
        DispatchQueue.main.async {
            
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
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
    
    @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer)
    {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        view.endEditing(true)
        return true
    }
}

extension LoginViewController {
    
    func dismissAnyVisibleKeyboards()
    {
        if(uuidTextField.isFirstResponder || apiKeyTextField.isFirstResponder)
        {
            view.endEditing(true)
        }
    }
}
