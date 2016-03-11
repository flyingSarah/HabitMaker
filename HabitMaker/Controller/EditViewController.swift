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
    
    var task: RepeatingTask? = nil
    
    var isDaily: Bool? = nil
    
    let priorityConversionArray = [0.5, 1.0, 1.5, 2.0]
    
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
            populateFields(task)
        }
        else if let isDaily = isDaily
        {
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
            print("Error opening Edit Task view: task is new and no type is known")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        task = nil
        isDaily = nil
        
        taskTitleField.text = ""
        repeatStepper.value = 0
        repeatNumberBox.text = "0"
        prioritySelector.selectedSegmentIndex = 1
        notesTextField.text = ""
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
        CoreDataStackManager.sharedInstance().saveContext()
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
        //TODO: figure out why this line crashes:
        //prioritySelector.selectedSegmentIndex = priorityConversionArray.indexOf(task.priority)!
        notesTextField.text = task.notes
    }
}
