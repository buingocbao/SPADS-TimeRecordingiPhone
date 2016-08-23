//
//  RecordingViewController.swift
//  SPADS-TimeRecordingiPhone
//
//  Created by BBaoBao on 7/9/15.
//  Copyright (c) 2015 buingocbao. All rights reserved.
//

import UIKit

class RecordingViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var btStart: MKButton!
    @IBOutlet weak var btEnd: MKButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lbBeacon: UILabel!

    var employeesInDay: NSArray = NSArray()
    
    var beaconRegion: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var isSearchingForBeacons = false
    var lastFoundBeacon: CLBeacon! = CLBeacon()
    var lastProximity: CLProximity! = CLProximity.Unknown
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Config button
        btStart.layer.shadowOpacity = 0.75
        btStart.layer.shadowRadius = 3.5
        btStart.layer.shadowColor = UIColor.blackColor().CGColor
        btStart.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
        
        btEnd.layer.shadowOpacity = 0.75
        btEnd.layer.shadowRadius = 3.5
        btEnd.layer.shadowColor = UIColor.blackColor().CGColor
        btEnd.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
        
        //Config Activity
        self.view.bringSubviewToFront(activityIndicator)
        activityIndicator.hidden = true
        activityIndicator.hidesWhenStopped = true
        
        //Config Beacon
        lbBeacon.hidden = true
        lbBeacon.numberOfLines = 0
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        let uuid = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
        beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 3157, minor: 27701, identifier: "www.spads.jp")
        
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringForRegion(beaconRegion)
        locationManager.startUpdatingLocation()
        
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        btStart.enabled = false
        btEnd.enabled = false
    }
    
    // MARK : Button Event
    @IBAction func btStartEvent(sender: AnyObject) {
        //Check current user
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        btStart.enabled = false
        btEnd.enabled = false
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            if let userObject = currentUser as PFUser? {
                let date = NSDate()
                let calendar = NSCalendar.currentCalendar()
                let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
                //let hour = String(components.hour)
                //let minutes = String(components.minute)
                let day = String(components.day)
                let month = String(components.month)
                let year = String(components.year)
                
                let daymonthyear = "\(day)-\(month)-\(year)"
                //let hourminute = "\(hour):\(minutes)"
                
                // Get all employees having Start Recording in current day-month-year
                let query = PFQuery(className: "TimeRecording").whereKey("Date", containsString: daymonthyear)
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    if error == nil {
                        print("Successfully retrieved \(objects!.count) employee")
                        self.employeesInDay = objects!
                        // Search for each Employee
                        for employee in self.employeesInDay {
                            let employeeObject = employee as! PFObject
                            //println(employeeObject["Employee"] as! String)
                            // Get Name of Each Employee
                            let employeeName = employeeObject["Employee"] as! String
                            let currentUser = userObject["username"] as! String
                            // If exist Employee Name in current day
                            if currentUser == employeeName {
                                let startTimeRecording = employeeObject["StartTimeRecord"] as! String
                                // Show Alert to notice about Time he/she started recording
                                self.activityIndicator.stopAnimating()
                                //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                self.btStart.enabled = true
                                self.btEnd.enabled = true
                                let alert = UIAlertController(title: "Time Recording Status", message: "You started your Time Recording at \(startTimeRecording) today.", preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        }
                        
                        if self.employeesInDay.count == 0 {
                            //if not exist Employee Name in current day
                            // Show Alert to notice about doing recording
                            self.activityIndicator.stopAnimating()
                            //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.btStart.enabled = true
                            self.btEnd.enabled = true
                            let alert = UIAlertController(title: "Time Recording Status", message: "You didn't start recording today. Do you want to do it right now ?", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                                (alert: UIAlertAction) -> Void in
                                // Start record start time to cloud if user choose OK
                                print("Start Recording Start Time")
                                self.recordStartTime()
                            }))
                            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func btEndEvent(sender: AnyObject) {
        //Check current user
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.btStart.enabled = false
        self.btEnd.enabled = false
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            if let userObject = currentUser as PFUser? {
                let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
                //let hour = String(components.hour)
                //let minutes = String(components.minute)
                let day = String(components.day)
                let month = String(components.month)
                let year = String(components.year)
                
                let daymonthyear = "\(day)-\(month)-\(year)"
                //let hourminute = "\(hour):\(minutes)"
                
                // Get all employees having Start Recording in current day-month-year
                let userName = userObject["username"] as! String
                let query = PFQuery(className: "TimeRecording").whereKey("Date", containsString: daymonthyear).whereKey("Employee", containsString: userName)
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    if error == nil {
                        print("Successfully retrieved \(objects!.count) employee")
                        self.employeesInDay = objects!
                        // Search for each Employee
                        for employee in self.employeesInDay {
                            let employeeObject = employee as! PFObject
                            //println(employeeObject["Employee"] as! String)
                            // Get Name of Each Employee
                            let employeeName = employeeObject["Employee"] as! String
                            // If exist Employee Name in current day
                            if userName == employeeName {
                                if let endTimeRecording = employeeObject["EndTimeRecord"] as? String {
                                    // Show Alert to notice about Time he/she has end time recording
                                    self.activityIndicator.stopAnimating()
                                    //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                    self.btStart.enabled = true
                                    self.btEnd.enabled = true
                                    let alert = UIAlertController(title: "Time Recording Status", message: "You recorded your End Time Recording at \(endTimeRecording) today.", preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                } else {
                                    let date = NSDate()
                                    let calendar = NSCalendar.currentCalendar()
                                    let components = calendar.components([.Hour, .Minute, .Day, .Month, .Year], fromDate: date)
                                    let hour = components.hour
                                    let minutes = components.minute
                                    
                                    if hour <= 18 && hour >= 9 {
                                        // Show Alert to notice about early ending time recording
                                        self.activityIndicator.stopAnimating()
                                        //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                        self.btStart.enabled = true
                                        self.btEnd.enabled = true
                                        let alert = UIAlertController(title: "Time Recording Status", message: "It's not the end of official hours. Do you REALLY want to end your time recording today", preferredStyle: UIAlertControllerStyle.Alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                                            (alert: UIAlertAction) -> Void in
                                            // Start recording end time to cloud if user choose OK
                                            print("Start Recording End Time")
                                            self.recordEndTime()
                                        }))
                                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    } else {
                                        self.recordEndTime()
                                        // Show Alert to notice about ending time recording
                                        self.activityIndicator.stopAnimating()
                                        //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                        self.btStart.enabled = true
                                        self.btEnd.enabled = true
                                        let alert = UIAlertController(title: "Time Recording Status", message: "You successfully recorded your ending time. Goodbye !!", preferredStyle: UIAlertControllerStyle.Alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                        
                        if self.employeesInDay.count == 0 {
                            // Show Alert to notice about ending time recording
                            self.activityIndicator.stopAnimating()
                            //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.btStart.enabled = true
                            self.btEnd.enabled = true
                            let alert = UIAlertController(title: "Time Recording Status", message: "It seems like you didn't make any recording today. Please contact to your manager for reporting.", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                })
            }
        }
    }
    
    func recordStartTime() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.btStart.enabled = false
        self.btEnd.enabled = false
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
        
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            if let userObject = currentUser as PFUser? {
                let timeRecording = PFObject(className:"TimeRecording")
                timeRecording["Employee"] = userObject["username"]
                timeRecording["Date"] = daymonthyear
                timeRecording["StartTimeRecord"] = hourminute
                timeRecording["Group"] = userObject["Group"]
                timeRecording.saveInBackgroundWithBlock({ (success, error) -> Void in
                    if success {
                        self.showSuccessFuntion("Start")
                    }
                })
            }
        }
    }
    
    func recordEndTime() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.btStart.enabled = false
        self.btEnd.enabled = false
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
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            if let userObject = currentUser as PFUser? {
                let userName = userObject["username"] as! String
                let query = PFQuery(className: "TimeRecording").whereKey("Date", containsString: daymonthyear).whereKey("Employee", containsString: userName)
                query.getFirstObjectInBackgroundWithBlock({ (object, error) -> Void in
                    if error != nil {
                        print(error)
                    } else if let employee = object {
                        employee["EndTimeRecord"] = hourminute
                        employee.saveInBackgroundWithBlock({ (success, error) -> Void in
                            if success {
                                self.showSuccessFuntion("End")
                            }
                        })
                    }
                })
            }
        }
    }
    
    func showSuccessFuntion(string: String){
        activityIndicator.stopAnimating()
        //UIApplication.sharedApplication().endIgnoringInteractionEvents()
        self.btStart.enabled = true
        self.btEnd.enabled = true
        let alert = UIAlertController(title: "Time Recording Status", message: "\(string) Time Recording Saved Successfully.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)

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
        lbBeacon.hidden = false
    }
    
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        lbBeacon.hidden = true
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        var shouldHideBeaconDetails = true
        
        if let foundBeacons = beacons {
            if foundBeacons.count > 0 {
                if let closestBeacon = foundBeacons[0] as? CLBeacon {
                    if closestBeacon != lastFoundBeacon || lastProximity != closestBeacon.proximity  {
                        lastFoundBeacon = closestBeacon
                        lastProximity = closestBeacon.proximity
                        
                        var proximityMessage: String!
                        switch lastFoundBeacon.proximity {
                        case CLProximity.Immediate:
                            proximityMessage = "Immediate"
                            //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.btStart.enabled = true
                            self.btEnd.enabled = true
                            
                        case CLProximity.Near:
                            proximityMessage = "Near"
                            //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.btStart.enabled = true
                            self.btEnd.enabled = true
                            
                        case CLProximity.Far:
                            proximityMessage = "Far"
                            //UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            self.btStart.enabled = true
                            self.btEnd.enabled = true
                            
                        default:
                            proximityMessage = "Can't find any Beacon"
                            //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                            self.btStart.enabled = false
                            self.btEnd.enabled = false
                        }
                        
                        shouldHideBeaconDetails = false
                        
                        lbBeacon.text = "Beacon Details:\nMajor = " + String(closestBeacon.major.intValue) + "\nMinor = " + String(closestBeacon.minor.intValue) + "\nDistance: " + proximityMessage
                    }
                }
            }
        }
        
        lbBeacon.hidden = shouldHideBeaconDetails
    }
}
