//
//  LoginViewController.swift
//  SPADS-TimeRecordingiPhone
//
//  Created by BBaoBao on 7/9/15.
//  Copyright (c) 2015 buingocbao. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var tfAccount: MKTextField!
    @IBOutlet weak var tfPassword: MKTextField!

    @IBOutlet weak var btLogin: MKButton!
    @IBOutlet weak var btRegister: MKButton!
    @IBOutlet weak var btForget: MKButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        activityIndicator.stopAnimating()
        
        //Check current user
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            self.performSegueWithIdentifier("LoginSegue", sender: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        
        //Get device size
        let bounds: CGRect = UIScreen.mainScreen().bounds
        let dvWidth:CGFloat = bounds.size.width
        let dvHeight:CGFloat = bounds.size.height
        
        //Motion Background
        // Make Motion background
        let backgroundImage:UIImageView = UIImageView(frame: CGRect(x: -50, y: -50, width: dvWidth+100, height: dvHeight+100))
        backgroundImage.image = UIImage(named: "Background.jpg")
        backgroundImage.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(backgroundImage)
        self.view.sendSubviewToBack(backgroundImage)
        
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -50
        horizontalMotionEffect.maximumRelativeValue = 50
        
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -50
        verticalMotionEffect.maximumRelativeValue = 50
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        backgroundImage.addMotionEffect(motionEffectGroup)

        // Email textfield
        tfAccount.layer.borderColor = UIColor.clearColor().CGColor
        tfAccount.floatingPlaceholderEnabled = true
        tfAccount.placeholder = "Email Account"
        //tfAccount.circleLayerColor = UIColor.MKColor.LightGreen
        tfAccount.tintColor = UIColor.MKColor.Green
        tfAccount.backgroundColor = UIColor(hex: 0xE0E0E0)
        self.view.bringSubviewToFront(tfAccount)
        self.tfAccount.delegate = self
        
        // Password Textfield
        tfPassword.layer.borderColor = UIColor.clearColor().CGColor
        tfPassword.floatingPlaceholderEnabled = true
        tfPassword.placeholder = "Password"
        //tfPassword.circleLayerColor = UIColor.MKColor.LightGreen
        tfPassword.tintColor = UIColor.MKColor.Green
        tfPassword.backgroundColor = UIColor(hex: 0xE0E0E0)
        self.view.bringSubviewToFront(tfPassword)
        self.tfPassword.delegate = self
        
        // Login Button
        btLogin.cornerRadius = 40.0
        btLogin.backgroundLayerCornerRadius = 40.0
        btLogin.maskEnabled = false
        btLogin.ripplePercent = 1.75
        btLogin.rippleLocation = .Center
        
        btLogin.layer.shadowOpacity = 0.75
        btLogin.layer.shadowRadius = 3.5
        btLogin.layer.shadowColor = UIColor.blackColor().CGColor
        btLogin.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
        
        // Register Button
        btRegister.cornerRadius = 40.0
        btRegister.backgroundLayerCornerRadius = 40.0
        btRegister.maskEnabled = false
        btRegister.ripplePercent = 1.75
        btRegister.rippleLocation = .Center
        
        btRegister.layer.shadowOpacity = 0.75
        btRegister.layer.shadowRadius = 3.5
        btRegister.layer.shadowColor = UIColor.blackColor().CGColor
        btRegister.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
        
        // Forgot password button
        //self.view.bringSubviewToFront(btRegister)
        
        btForget.layer.shadowOpacity = 0.75
        btForget.layer.shadowRadius = 3.5
        btForget.layer.shadowColor = UIColor.blackColor().CGColor
        btForget.layer.shadowOffset = CGSize(width: 1.0, height: 5.5)
        
        // Progress icon for logging
        self.view.bringSubviewToFront(activityIndicator)
        activityIndicator.hidden = true
        activityIndicator.hidesWhenStopped = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(userText: UITextField) -> Bool {
        checkLogin()
        return true;
    }
    
    func checkLogin() {
        // Start activity indicator
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        // The textfields are not completed
        if (self.tfAccount.text == "") || (self.tfPassword.text == "") {
            var alert = UIAlertController(title: "Login Failed", message: "Please fill your email and password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        PFUser.logInWithUsernameInBackground(tfAccount.text, password:tfPassword.text) {
            (user: PFUser?, error: NSError?) -> Void in
            if user != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    self.performSegueWithIdentifier("LoginSegue", sender: false)
                }
                self.tfAccount.text = ""
                self.tfPassword.text = ""
            } else {
                // The login failed. Check error to see why.
                var alert = UIAlertController(title: "Login Failed", message: "Please check your email or password", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                self.activityIndicator.stopAnimating()
            }
        }
        tfAccount.placeholder = "Email Account"
        catchLoginEvent()
    }
    
    func catchLoginEvent() {
        btLogin.addTarget(self, action: "btLogin:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    func processSignUp() {
        var userEmailAddress = tfAccount.text
        var userPassword = tfPassword.text
        
        // Ensure username is lowercase
        userEmailAddress = userEmailAddress.lowercaseString
        
        // Add email address validation
        
        // Start activity indicator
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        // Create the user
        var user = PFUser()
        user.username = userEmailAddress
        user.password = userPassword
        user.email = userEmailAddress
        
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError?) -> Void in
            if error == nil {
                self.activityIndicator.stopAnimating()
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("LoginSegue", sender: false)
                }
                self.tfAccount.text = ""
                self.tfPassword.text = ""
            } else {
                self.activityIndicator.stopAnimating()
                if let message: AnyObject = error!.userInfo["error"] {
                    var alert = UIAlertController(title: "Register Failed", message: message as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
        
        tfAccount.placeholder = "Email Account"
    }
    
    // Check validate email
    func validate(value: String) -> Bool {
        let emailRule = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", emailRule)
        return phoneTest.evaluateWithObject(value)
    }

    // MARK: - Button Event
    
    @IBAction func btLogin(sender: AnyObject) {
        checkLogin()
    }
    
    @IBAction func btRegister(sender: AnyObject) {
        if (self.tfAccount.text == "") || (self.tfPassword.text == "") {
            let alert = UIAlertController(title: "Register Failed", message: "Please fill your email and password", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            // Build the terms and conditions alert
            let alertController = UIAlertController(title: "Agree to terms and conditions",
                message: "Click I AGREE to signal that you agree to the End User Licence Agreement.",
                preferredStyle: UIAlertControllerStyle.Alert
            )
            alertController.addAction(UIAlertAction(title: "I AGREE",
                style: UIAlertActionStyle.Default,
                handler: { alertController in self.processSignUp()})
            )
            alertController.addAction(UIAlertAction(title: "I do NOT agree",
                style: UIAlertActionStyle.Default,
                handler: nil)
            )
            // Display alert
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func btForget(sender: AnyObject) {
        if tfAccount.text == "" {
            //tfAccount.placeholder = "To reset password, please enter email"
            var alert = UIAlertController(title: "Forget Password", message: "Please enter your email to Email Account textfield, then touch Forget password again.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            if validate(tfAccount.text) {
                tfAccount.textColor = UIColor.blackColor()
                tfAccount.placeholder = "Email Account"
                PFUser.requestPasswordResetForEmailInBackground(tfAccount.text)
                var alert = UIAlertController(title: "Forget Password", message: "Please check your email to continue resetting process", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                tfAccount.placeholder = "Email Account"
            } else {
                tfAccount.textColor = UIColor.redColor()
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        tfAccount.textColor = UIColor.blackColor()
        tfAccount.placeholder = "Email Account"
    }
    
}
