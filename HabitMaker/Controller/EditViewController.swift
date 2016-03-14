//
//  EditViewController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/9/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import UIKit

class EditViewController: UIViewController, UITextFieldDelegate {
    
    //MARK -- Outlets
    
    @IBOutlet weak var taskTitleField: UITextField!
    @IBOutlet weak var repeatNumberBox: UILabel!
    @IBOutlet weak var repeatStepper: UIStepper!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var notesTextField: UITextView!
    @IBOutlet weak var repetitionsLabel: UILabel!
    
    //MARK -- Useful Variables
    
    var task: RepeatingTask? = nil //this is given a task if we're editing an existing task
    
    var isDaily: Bool? = nil //so we know if we're making a daily task or a weekly task
    
    var makeNewTask: Bool? = nil //edit view can either make a new task or update an existing task
    
    var updatesToSend = [String: AnyObject]() //if any parameters are modified they are added to this array to send to the Habitica client whenever save is selected
    
    let priorityConversionArray = [0.1, 1.0, 1.5, 2.0] //to easily convert priority parameters to and from Habitica's format (values of the array) and the format the priority selector uses (indexes of the array)
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        taskTitleField.delegate = self
        
        //add a little left indent/padding on the text field
        //Found how to do this from this stackoverflow topic: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
        let taskTitleSpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        taskTitleField.leftViewMode = UITextFieldViewMode.Always
        taskTitleField.leftView = taskTitleSpacerView
        
        repeatStepper.maximumValue = 100
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //find out if editing an existing task or creating a new one
        if let task = task
        {
            makeNewTask = false
            
            populateFields(task)
        }
        else if let isDaily = isDaily
        {
            makeNewTask = true
            
            if(isDaily)
            {
                repetitionsLabel.text = "Number of Repetitions per Day:"
            }
            else
            {
                repetitionsLabel.text = "Number of Repetitions per Week:"
            }
        }
        else
        {
            //this should never happen
            print("Error opening Edit Task view: task is new and no type is known")
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
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
    
    @IBAction func repeatStepperValueChanged(sender: UIStepper)
    {
        repeatNumberBox.text = "\(Int(sender.value))"
    }
    
    @IBAction func prioritySelector(sender: UISegmentedControl)
    {
        //print("priority selector value changed \(sender.selectedSegmentIndex)")
        
        task?.priority = priorityConversionArray[sender.selectedSegmentIndex]
    }
    
    @IBAction func cancel(sender: UIButton)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: AnyObject)
    {
        //TODO: send the updates to send dictionary to the habitica client's update existing task function.... or if we are modifying an existing task, send it to the make new task function
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
}
