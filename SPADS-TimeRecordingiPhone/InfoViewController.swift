//
//  InfoViewController.swift
//  SPADS-TimeRecordingiPhone
//
//  Created by BBaoBao on 7/25/15.
//  Copyright (c) 2015 buingocbao. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var btLogout: MKButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        btLogout.backgroundColor = UIColor.MKColor.Red
        btLogout.layer.shadowOpacity = 0.75
        btLogout.layer.shadowRadius = 3.5
        btLogout.layer.shadowColor = UIColor.blackColor().CGColor
        btLogout.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btLogoutEvent(sender: AnyObject) {
        
        PFUser.logOut()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") 
        self.presentViewController(vc, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
