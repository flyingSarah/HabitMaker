//
//  DailyTasksController.swift
//  HabitMaker
//
//  Created by Sarah Howe on 3/2/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import Foundation
import UIKit

class DailyTasksController: UITableViewController {
    
    //MARK -- Outlets
    @IBOutlet var taskTable: UITableView!
    
    //MARK -- Useful Variables
    
    
    //MARK -- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading daily tasks...")
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
    }
    
}