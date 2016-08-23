//
//  AppDelegate.swift
//  SPADS-TimeRecordingiPhone
//
//  Created by BBaoBao on 7/9/15.
//  Copyright (c) 2015 buingocbao. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    // Beacon variables
    var beaconRegion: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var isSearchingForBeacons = false
    var lastFoundBeacon: CLBeacon! = CLBeacon()
    var lastProximity: CLProximity! = CLProximity.Unknown

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Parse.enableLocalDatastore()
        Parse.setApplicationId("4OnWb9XZC1jm5FpuH8J6JTaH2Gq1obJvudbE4aba", clientKey:"SbxRQuDpfoT0pqWzcYHOuLV5uBnlpYIDvUQMTQg2")
        
        // MARK: Beacon settings
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        let uuid = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
        beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 3157, minor: 27701, identifier: "www.spads.jp")
        
        locationManager = CLLocationManager()
        if ((locationManager?.respondsToSelector("requestAlwaysAuthorization")) != nil) {
            locationManager?.requestAlwaysAuthorization()
        }
        locationManager?.delegate = self
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.startMonitoringForRegion(beaconRegion)
        locationManager?.startRangingBeaconsInRegion(beaconRegion)
        locationManager?.startUpdatingLocation()
        
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Sound],
                    categories: nil
                )
            )
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    // MARK: CLLocationManagerDelegate
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        notification.soundName = "NotificationSound.m4a"
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        locationManager.requestStateForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if state == CLRegionState.Inside {
            locationManager.startRangingBeaconsInRegion(beaconRegion)
        }
        else {
            locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
        manager.startUpdatingLocation()
        
        print("You entered the region")
        recordTime()
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
        manager.stopUpdatingLocation()
        
        print("You exited the region")

        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            if let userObject = currentUser as PFUser? {
                let date = NSDate()
                let calendar = NSCalendar.currentCalendar()
                let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
                let hour = String(components.hour)
                let minutes = String(components.minute)
                let day = String(components.day)
                let month = String(components.month)
                let year = String(components.year)
                
                let daymonthyear = "\(day)-\(month)-\(year)"
                let hourminute = "\(hour):\(minutes)"
                
                // Get all employees having Start Recording in current day-month-year
                let userName = userObject["username"] as! String
                let query = PFQuery(className: "TimeRecording").whereKey("Date", containsString: daymonthyear).whereKey("Employee", containsString: userName)
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    if error == nil {
                        print("Successfully retrieved \(objects!.count) employee")
                        let arrayObjects: NSArray = objects!
                        // Search for each Employee
                        for employee in arrayObjects {
                            let employeeObject = employee as! PFObject
                            if let temp = employeeObject["EndTimeRecord"] as? String {
                                // Had End Time Record
                            } else {
                                // Dont have End Time Record
                                if Int(hour) <= 18 && Int(hour) >= 9 { // Current in official hours
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    if let noticed = defaults.stringForKey("isNoticedExitIn")
                                    {
                                        if noticed == daymonthyear {
                                            //Do nothing
                                        } else {
                                            // Push 1 time
                                            self.sendLocalNotificationWithMessage("It's not the end of office hours. Please come back as soon as you can")
                                            
                                            // Check that is Noticed
                                            let defaults = NSUserDefaults.standardUserDefaults()
                                            defaults.setObject(daymonthyear, forKey: "isNoticedExitIn")
                                        }
                                    } else {
                                        // First time run app
                                        self.sendLocalNotificationWithMessage("It's not the end of office hours. Please come back as soon as you can")
                                        
                                        // Check that is Noticed
                                        let defaults = NSUserDefaults.standardUserDefaults()
                                        defaults.setObject(daymonthyear, forKey: "isNoticedExitIn")
                                    }
                                } else if Int(hour) >= 18 { // Not current in official hours
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    if let noticed = defaults.stringForKey("isNoticedExitOut")
                                    {
                                        if noticed == daymonthyear {
                                            //Do nothing
                                        } else {
                                            // Push 1 time
                                            //self.sendLocalNotificationWithMessage("You didn't make any End Time Recording, please open Time Recording application to do it.")
                                            // Record
                                            query.getFirstObjectInBackgroundWithBlock({ (object, error) -> Void in
                                                if error != nil {
                                                    print(error)
                                                } else if let employee = object {
                                                    employee["EndTimeRecord"] = hourminute
                                                    employee.saveInBackgroundWithBlock({ (success, error) -> Void in
                                                        if success {
                                                            self.sendLocalNotificationWithMessage("You successfully recorded your end work today. Good evening !!")
                                                        }
                                                    })
                                                }
                                            })
                                            
                                            // Check that is Noticed
                                            let defaults = NSUserDefaults.standardUserDefaults()
                                            defaults.setObject(daymonthyear, forKey: "isNoticedExitOut")
                                        }
                                    } else {
                                        // First time run app
                                        //self.sendLocalNotificationWithMessage("You didn't make any End Time Recording, please open Time Recording application to do it.")
                                        
                                        // Record
                                        query.getFirstObjectInBackgroundWithBlock({ (object, error) -> Void in
                                            if error != nil {
                                                print(error)
                                            } else if let employee = object {
                                                employee["EndTimeRecord"] = hourminute
                                                employee.saveInBackgroundWithBlock({ (success, error) -> Void in
                                                    if success {
                                                        self.sendLocalNotificationWithMessage("You successfully recorded your end work today. Good evening !!")
                                                    }
                                                })
                                            }
                                        })
                                        
                                        // Check that is Noticed
                                        let defaults = NSUserDefaults.standardUserDefaults()
                                        defaults.setObject(daymonthyear, forKey: "isNoticedExitOut")
                                    }
                                    
                                }
                            }
                        }
                        
                        if arrayObjects.count == 0 {
                            let defaults = NSUserDefaults.standardUserDefaults()
                            if let noticed = defaults.stringForKey("isNoticedExitError")
                            {
                                if noticed == daymonthyear {
                                    //Do nothing
                                } else {
                                    // Push 1 time
                                    self.sendLocalNotificationWithMessage("Seem like you didn't make any record today. Please contact to your manager for reporting!")
                                    
                                    // Check that is Noticed
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    defaults.setObject(daymonthyear, forKey: "isNoticedExitError")
                                }
                            } else {
                                // First time run app
                                self.sendLocalNotificationWithMessage("Seem like you didn't make any record today. Please contact to your manager for reporting!")
                                
                                // Check that is Noticed
                                let defaults = NSUserDefaults.standardUserDefaults()
                                defaults.setObject(daymonthyear, forKey: "isNoticedExitError")
                            }
                        }
                    }
                })
            }
        }
    }
    
    func recordTime() {
        // TODO : Check if user recorded
        //Check current user
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            // Check day
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
            let hour = String(components.hour)
            let minutes = String(components.minute)
            let day = String(components.day)
            let month = String(components.month)
            let year = String(components.year)
            
            let daymonthyear = "\(day)-\(month)-\(year)"
            let hourminute = "\(hour):\(minutes)"
            
            if let userObject = currentUser as PFUser? {
                // Get all employees having Start Recording in current day-month-year
                let userName = userObject["username"] as! String
                let query = PFQuery(className: "TimeRecording").whereKey("Date", containsString: daymonthyear).whereKey("Employee", containsString: userName)
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    if error == nil {
                        print("Successfully retrieved \(objects!.count) employee")
                        let arrayObjects: NSArray = objects!
                        for employee in arrayObjects {
                            let employeeObject = employee as! PFObject
                            // Get Name of Each Employee
                            let employeeName = employeeObject["Employee"] as! String
                            // If exist Employee Name in current day
                            if userName == employeeName {
                                //Do something if exist employee that make start time record
                                //self.sendLocalNotificationWithMessage("Welcome back to SPADS JOINT STOCK COMPANY")
                            }
                        }
                        if arrayObjects.count == 0 {
                            if Int(hour) > 9 && Int(hour) < 18 {
                                self.sendLocalNotificationWithMessage("Welcome to SPADS JOINT STOCK COMPANY")
                                // No exist, make record
                                let timeRecording = PFObject(className:"TimeRecording")
                                timeRecording["Employee"] = userObject["username"]
                                timeRecording["Date"] = daymonthyear
                                timeRecording["StartTimeRecord"] = hourminute
                                timeRecording["Group"] = userObject["Group"]
                                timeRecording.saveInBackgroundWithBlock({ (success, error) -> Void in
                                    if success {
                                        self.sendLocalNotificationWithMessage("You successfully recorded your start work today. Happy working !!")
                                    }
                                })
                            }
                        }
                    }
                })
            }
        } else {
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
            let day = String(components.day)
            let month = String(components.month)
            let year = String(components.year)
            
            let daymonthyear = "\(day)-\(month)-\(year)"

            let defaults = NSUserDefaults.standardUserDefaults()
            if let noticed = defaults.stringForKey("isNoticedEnter")
            {
                // Check day
                if noticed == daymonthyear {
                    //Do Nothing
                } else {
                    //Different day
                    sendLocalNotificationWithMessage("Welcome to SPADS JOINT STOCK COMPANY")
                    sendLocalNotificationWithMessage("You are not logging into our Time Record Application. If you're our employee, please login and do Time Recording by manually through our Application.")
                    
                    // Check that is Noticed
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(daymonthyear, forKey: "isNoticedEnter")
                }
            } else {
                // First time run app
                sendLocalNotificationWithMessage("Welcome to SPADS JOINT STOCK COMPANY")
                sendLocalNotificationWithMessage("You are not logging into our Time Record Application. If you're our employee, please login and do Time Recording by manually through our Application.")
                
                // Check that is Noticed
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(daymonthyear, forKey: "isNoticedEnter")
            }
            
        }
    }
}

