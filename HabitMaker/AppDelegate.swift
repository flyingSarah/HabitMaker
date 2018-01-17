//
//  AppDelegate.swift
//  HabitMaker
//
//  Created by Sarah Howe on 2/7/16.
//  Copyright (c) 2016 SarahHowe. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //set the app theme color
        window?.tintColor = UIColor(red: 0.263, green: 0.169, blue: 0.447, alpha: 1.0)
        
        return true
    }
}

