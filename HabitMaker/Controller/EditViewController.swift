//
//  EditViewController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/9/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import UIKit

class EditViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    //MARK -- Outlets
    
    @IBOutlet weak var taskTitleField: UITextField!
    @IBOutlet weak var repeatNumberBox: UILabel!
    @IBOutlet weak var repeatStepper: UIStepper!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var notesTextField: UITextView!
    @IBOutlet weak var repetitionsLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK -- Useful Variables
    
    var task: RepeatingTask? = nil //this is given a task if we're editing an existing task
    
    var isDaily: Bool? = nil //so we know if we're making a daily task or a weekly task
    
    var makeNewTask: Bool? = nil //edit view can either make a new task or update an existing task
    
    var updatesToSend = [String: AnyObject]() //if any parameters are modified they are added to this array to send to the Habitica client whenever save is selected
    
    let priorityConversionArray = [0.1, 1.0, 1.5, 2.0] //to easily convert priority parameters to and from Habitica's format (values of the array) and the format the priority selector uses (indexes of the array)
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        taskTitleField.delegate = self
        notesTextField.delegate = self
        
        //add a little left indent/padding on the text field
        //Found how to do this from this stackoverflow topic: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
        let taskTitleSpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        taskTitleField.leftViewMode = UITextFieldViewMode.Always
        taskTitleField.leftView = taskTitleSpacerView
        
        repeatStepper.maximumValue = 100
        
        //initialize tap recognizer
        tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
        tapRecognizer!.numberOfTapsRequired = 1
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addKeyboardDismissRecognizer()
        subscribeToKeyboardNotifications()
        
        //find out if editing an existing task or creating a new one
        if let task = task
        {
            makeNewTask = false
            
            populateFields(task)
        }
        else if let isDaily = isDaily
        {
            makeNewTask = true
            
            saveButton.enabled = false
            
            if(isDaily)
            {
                repetitionsLabel.text = "Number of Repetitions per Day:"
                repeatStepper.minimumValue = 0
            }
            else
            {
                repetitionsLabel.text = "Number of Repetitions per Week:"
                repeatStepper.minimumValue = 1
                repeatNumberBox.text = "\(Int(repeatStepper.value))"
            }
        }
        else
        {
            //this only happens if the edit view is left open and you tab back and forth between task types - the edit view should dissapear when that occurs
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeKeyboardDismissRecognizer()
        unsubscribeFromKeyboardNotifications()
        
        task = nil
        isDaily = nil
        
        taskTitleField.text = ""
        repeatStepper.value = 0
        repeatNumberBox.text = "0"
        prioritySelector.selectedSegmentIndex = 1
        notesTextField.text = ""
        
        updatesToSend.removeAll()
    }
    
    //MARK -- Actions
    
    @IBAction func titleFieldChanged(sender: UITextField)
    {
        if(sender.text!.isEmpty)
        {
            saveButton.enabled = false
        }
        else
        {
            saveButton.enabled = true
        }
        
        if let task = task
        {
            task.text = sender.text!
        }
        
        
        updatesToSend[HabiticaClient.TaskSchemaKeys.TEXT] = sender.text!
    }
    
    @IBAction func repeatStepperValueChanged(sender: UIStepper)
    {
        let repeatValue = Int(sender.value)
        
        repeatNumberBox.text = "\(repeatValue)"
        
        var numFinRepeats = 0
        
        if let task = task
        {
            //the number of finished repeats shouldn't be greater than the number of repeats
            if(task.numFinRepeats.integerValue > repeatValue)
            {
                numFinRepeats = repeatValue
            }
            else
            {
                numFinRepeats = task.numFinRepeats.integerValue
            }
            
            task.numFinRepeats = numFinRepeats
            task.numRepeats = repeatValue
        }
        
        //set the repeat checklist array and add it to our updates to send
        updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = RepeatingTask.makeChecklistArray(repeatValue, numFinRepeats: numFinRepeats)
    }
    
    @IBAction func prioritySelector(sender: UISegmentedControl)
    {
        let priority = priorityConversionArray[sender.selectedSegmentIndex]
        
        if let task = task
        {
            task.priority = priority
        }
        
        updatesToSend[HabiticaClient.TaskSchemaKeys.PRIORITY] = priority
    }
    
    @IBAction func save(sender: AnyObject)
    {
        activityIndicator.startAnimating()
        
        dismissAnyVisibleKeyboards()
        
        //send the updatesToSend dictionary to the habitica client's updateExistingTask function.... or if we are modifying an existing task, send it to the createNewTask function
        if let makeNewTask = makeNewTask
        {
            //send the updates to Habitica
            let uuid = HabiticaClient.sharedInstance.uuid
            let apiKey = HabiticaClient.sharedInstance.apiKey
            
            if(makeNewTask)
            {
                setWeeklyRepeatDefaults()
                
                updatesToSend[HabiticaClient.TaskSchemaKeys.TYPE] = "daily"
                
                HabiticaClient.sharedInstance.createNewTask(uuid, apiKey: apiKey, jsonBody: updatesToSend) { result, error in
                    
                    if let error = error
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            self.activityIndicator.stopAnimating()
                        }
                        
                        let failureString = error.localizedDescription
                        self.showAlertController("Create New Task Error", message: failureString)
                    }
                    else
                    {
                        if let newTask = result as? [String: AnyObject]
                        {
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                //create the repeating task for each of the chosen tasks
                                let _ = RepeatingTask(repeatingTask: newTask, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                                
                                CoreDataStackManager.sharedInstance().saveContext()
                                
                                self.activityIndicator.stopAnimating()
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                    }
                }
            }
            else
            {
                HabiticaClient.sharedInstance.updateExistingTask(uuid, apiKey: apiKey, taskID: task!.id!, jsonBody: updatesToSend) { result, error in
                    
                    if let error = error
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            self.activityIndicator.stopAnimating()
                        }
                        
                        let failureString = error.localizedDescription
                        self.showAlertController("Update Task Error", message: failureString)
                    }
                    else
                    {
                        //save the context if the response from habitica is successful
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                            
                            self.activityIndicator.stopAnimating()
                            
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                }
            }
        }
        else
        {
            activityIndicator.stopAnimating()
            
            showAlertController("Edit Task Saving Error", message: "creating new or editing existing - definition ambiguous")
        }
    }
    
    //MARK -- Delegates
    
    func textViewDidChange(textView: UITextView)
    {
        if let task = task
        {
            task.notes = textView.text
        }
        
        updatesToSend[HabiticaClient.TaskSchemaKeys.NOTES] = textView.text
    }
    
    
    //MARK -- Configure Cells
    
    func populateFields(task: RepeatingTask)
    {
        isDaily = task.isDaily
        
        if(task.isDaily)
        {
            repetitionsLabel.text = "Number of Repetitions per Day:"
        }
        else
        {
            repetitionsLabel.text = "Number of Repetitions per Week:"
        }
        
        taskTitleField.text = task.text
        repeatStepper.value = task.numRepeats.doubleValue
        repeatNumberBox.text = task.numRepeats.stringValue
        prioritySelector.selectedSegmentIndex = priorityConversionArray.indexOf(task.priority)!
        notesTextField.text = task.notes
    }
    
    //MARK -- Helper Functions
    
    func setWeeklyRepeatDefaults()
    {
        if let isDaily = isDaily
        {
            if(!isDaily)
            {
                updatesToSend[HabiticaClient.TaskSchemaKeys.REPEAT] = [
                    HabiticaClient.RepeatWeekdayKeys.SUN: true,
                    HabiticaClient.RepeatWeekdayKeys.MON: false,
                    HabiticaClient.RepeatWeekdayKeys.TUES: false,
                    HabiticaClient.RepeatWeekdayKeys.WED: false,
                    HabiticaClient.RepeatWeekdayKeys.THURS: false,
                    HabiticaClient.RepeatWeekdayKeys.FRI: false,
                    HabiticaClient.RepeatWeekdayKeys.SAT: false
                ]
            }
            else
            {
                updatesToSend[HabiticaClient.TaskSchemaKeys.REPEAT] = [
                    HabiticaClient.RepeatWeekdayKeys.SUN: true,
                    HabiticaClient.RepeatWeekdayKeys.MON: true,
                    HabiticaClient.RepeatWeekdayKeys.TUES: true,
                    HabiticaClient.RepeatWeekdayKeys.WED: true,
                    HabiticaClient.RepeatWeekdayKeys.THURS: true,
                    HabiticaClient.RepeatWeekdayKeys.FRI: true,
                    HabiticaClient.RepeatWeekdayKeys.SAT: true
                ]
            }
        }
        
        updatesToSend[HabiticaClient.TaskSchemaKeys.CHECKLIST] = RepeatingTask.makeChecklistArray(Int(repeatStepper.value), numFinRepeats: 0)
    }
    
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
    
    //Shifting the keyboard so it does not hide controls
    func subscribeToKeyboardNotifications()
    {
        //subscribe to keyboardWillShow & keyboardWillHide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications()
    {
        //unsubscribe from keyboardWillShow & keyboardWillHide notifications
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification)
    {
        //shift the view's frame up so that controls are shown
        if(notesTextField.isFirstResponder())
        {
            view.frame.origin.y = -getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        //shift the view's frame back down so that the view is back to its original placement
        if(notesTextField.isFirstResponder())
        {
            view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat
    {
        //get and return the keyboard's height from the notification
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue //of CGRect
        
        return keyboardSize.CGRectValue().height
    }
}

extension EditViewController {
    
    func dismissAnyVisibleKeyboards()
    {
        if(taskTitleField.isFirstResponder() || notesTextField.isFirstResponder())
        {
            view.endEditing(true)
        }
    }
}