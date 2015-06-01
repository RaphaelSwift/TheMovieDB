//
//  LoginViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var headerTextLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: BorderedButton!
    @IBOutlet weak var debugTextLabel: UILabel!
    
    var appDelegate: AppDelegate!
    var session: NSURLSession!
    
    var backgroundGradient: CAGradientLayer? = nil
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    /* Based on student comments, this was added to help with smaller resolution devices */
    var keyboardAdjusted = false
    var lastKeyboardOffset : CGFloat = 0.0
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get the app delegate */
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        /* Get the shared URL session */
        session = NSURLSession.sharedSession()
        
        /* Configure the UI */
        self.configureUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addKeyboardDismissRecognizer()
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.removeKeyboardDismissRecognizer()
        self.unsubscribeToKeyboardNotifications()
    }

    // MARK: - Keyboard Fixes
    
    func addKeyboardDismissRecognizer() {
        self.view.addGestureRecognizer(tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer() {
        self.view.removeGestureRecognizer(tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // MARK: - Login
    
    @IBAction func loginButtonTouch(sender: AnyObject) {
        if usernameTextField.text.isEmpty {
            debugTextLabel.text = "Username Empty."
        } else if passwordTextField.text.isEmpty {
            debugTextLabel.text = "Password Empty."
        } else {
            
            /*
                Steps for Authentication...
                https://www.themoviedb.org/documentation/api/sessions
                
                Step 1: Create a new request token
            
                Step 2: Ask the user for permission via the API ("login")
                Step 3: Create a session ID
                
                Extra Steps...
                Step 4: Go ahead and get the user id ;)
                Step 5: Got everything we need, go to the next view!
            
            */
            self.getRequestToken()
        }
    }
    
    func completeLogin() {
        dispatch_async(dispatch_get_main_queue(), {
            self.debugTextLabel.text = ""
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MoviesTabBarController") as! UITabBarController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    // MARK: - Service Calls    
    
    func getRequestToken() {
        
        /* TASK: Get a request token, then store it (appDelegate.requestToken) and login with the token */
        
        /* 1. Set the parameters */
        let methodParameters = [
            "api_key": appDelegate.apiKey
        ]
        
        /* 2. Build the URL */
        let methodName = "/authentication/token/new"
        let urlString = appDelegate.baseURLSecureString + methodName + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
    
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            if let error = downloadError {
                dispatch_async(dispatch_get_main_queue()) {
                self.debugTextLabel.text = "Unable to make the request"
                //println("getRequestToken: Print an error message")
                }
                
            } else {
                
                /* 5. Parse the data */
                var parseError: NSError? = nil
                let parsedDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as! NSDictionary
                println(parsedDictionary)
                
                /* 6. Use the data! */
                
                if let token = parsedDictionary["request_token"] as? String {
                    self.appDelegate.requestToken = token
                    self.loginWithToken(self.appDelegate.requestToken!)
                    self.getSessionID(self.appDelegate.requestToken!)
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.debugTextLabel.text = "Could not find token key in \(parsedDictionary)"
                    }
                }
                
                
            }
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    func loginWithToken(requestToken: String) {
        
        /* TASK: Login, then get a session id */
        /* 1. Set the parameters */
    let methodParameters = [
        "api_key": appDelegate.apiKey,
        "request_token": requestToken,
        "username": usernameTextField.text,
        "password": passwordTextField.text
        ]
        /* 2. Build the URL */
        let baseUrl = appDelegate.baseURLSecureString
        let method = "authentication/token/validate_with_login" // authenticate a user with a TMDb username and password
        
        let urlString = NSURL(string: baseUrl + method + self.appDelegate.escapedParameters(methodParameters))!
        
        /* 3. Configure the request */
        
        let request = NSMutableURLRequest(URL: urlString)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        /* 4. Make the request */
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            if let error = downloadError {
                dispatch_async(dispatch_get_main_queue()) {
                    self.debugTextLabel.text = " Unable to make the request "
                }
            } else {
                /* 5. Parse the data */
                
                var parsingError: NSError? = nil
                let parsingDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                println(parsingDictionary)
                
                /* 6. Use the data! */
                if let loggedIn = parsingDictionary["success"] as? Bool {
                    if loggedIn {
                        dispatch_async(dispatch_get_main_queue()) {
                            println("Login Complete") }
                            
                    } else {
                        if let statusCode = parsingDictionary["status_code"] as? Int {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.debugTextLabel.text = parsingDictionary["status_code"] as? String
                            }
                        } else {
                        self.debugTextLabel.text = "Failure"
                        }
                    
                }
            }
        
        }
    }
        

        
        /* 7. Start the request */
        
        task.resume()
    }
    
    func getSessionID(requestToken: String) {
        
        /* TASK: Get a session ID, then store it (appDelegate.sessionID) and get the user's id */
        /* 1. Set the parameters */
        let methodParameters = [
            "api_key" : appDelegate.apiKey,
            "request_token" : requestToken
        ]
        
        /* 2. Build the URL */
        let baseUrl = appDelegate.baseURLSecureString
        let methodName = "authentication/session/new"
        
        let urlString = baseUrl + methodName + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                dispatch_async(dispatch_get_main_queue() ) {
                    self.debugTextLabel.text = "Could not perform request with method \(methodName)"
                }

            } else {
                /* 5. Parse the data */
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                /* 6. Use the data! */
                
                if let sessionID = parsedResult["session_id"] as? String {
                    self.appDelegate.sessionID = sessionID
                    self.getUserID(sessionID)
                    println(sessionID)
                } else {
                    dispatch_async(dispatch_get_main_queue() ) {
                        self.debugTextLabel.text = " Could not get a sessionID in : \(parsedResult)"
                    }
                }
                
                
                
            }
            
        }
        
        /* 7. Start the request */
        
        task.resume()
    }
    
    func getUserID(session_id : String) {
        
        /* TASK: Get the user's ID, then store it (appDelegate.userID) for future use and go to next view! */
        /* 1. Set the parameters */
        let methodParameters = [
            "api_key" : appDelegate.apiKey,
            "session_id" : session_id
         ]
        
        /* 2. Build the URL */
        let baseUrl = appDelegate.baseURLSecureString
        let methodName = "account"
        let urlString = baseUrl + methodName + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                dispatch_async(dispatch_get_main_queue() ) {
                    self.debugTextLabel.text = "Unable to to make the request"
                }
            } else {
                /* 5. Parse the data */
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                /* 6. Use the data! */
                println(parsedResult)
                if let userID = parsedResult["id"] as? Int {
                    self.appDelegate.userID = userID
                    self.completeLogin()
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.debugTextLabel.text = " Failed to get the user ID "
                }
            }
            
        }
        }
        
        /* 7. Start the request */
        
        task.resume()
    }
}

// MARK: - Helper

extension LoginViewController {
    
    func configureUI() {
        
        /* Configure background gradient */
        self.view.backgroundColor = UIColor.clearColor()
        let colorTop = UIColor(red: 0.345, green: 0.839, blue: 0.988, alpha: 1.0).CGColor
        let colorBottom = UIColor(red: 0.023, green: 0.569, blue: 0.910, alpha: 1.0).CGColor
        self.backgroundGradient = CAGradientLayer()
        self.backgroundGradient!.colors = [colorTop, colorBottom]
        self.backgroundGradient!.locations = [0.0, 1.0]
        self.backgroundGradient!.frame = view.frame
        self.view.layer.insertSublayer(self.backgroundGradient, atIndex: 0)
        
        /* Configure header text label */
        headerTextLabel.font = UIFont(name: "AvenirNext-Medium", size: 24.0)
        headerTextLabel.textColor = UIColor.whiteColor()
        
        /* Configure email textfield */
        let emailTextFieldPaddingViewFrame = CGRectMake(0.0, 0.0, 13.0, 0.0);
        let emailTextFieldPaddingView = UIView(frame: emailTextFieldPaddingViewFrame)
        usernameTextField.leftView = emailTextFieldPaddingView
        usernameTextField.leftViewMode = .Always
        usernameTextField.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        usernameTextField.backgroundColor = UIColor(red: 0.702, green: 0.863, blue: 0.929, alpha:1.0)
        usernameTextField.textColor = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
        usernameTextField.attributedPlaceholder = NSAttributedString(string: usernameTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        usernameTextField.tintColor = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
        
        /* Configure password textfield */
        let passwordTextFieldPaddingViewFrame = CGRectMake(0.0, 0.0, 13.0, 0.0);
        let passwordTextFieldPaddingView = UIView(frame: passwordTextFieldPaddingViewFrame)
        passwordTextField.leftView = passwordTextFieldPaddingView
        passwordTextField.leftViewMode = .Always
        passwordTextField.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        passwordTextField.backgroundColor = UIColor(red: 0.702, green: 0.863, blue: 0.929, alpha:1.0)
        passwordTextField.textColor = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: passwordTextField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordTextField.tintColor = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
        
        /* Configure debug text label */
        headerTextLabel.font = UIFont(name: "AvenirNext-Medium", size: 20)
        headerTextLabel.textColor = UIColor.whiteColor()
        
        /* Configure tap recognizer */
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer?.numberOfTapsRequired = 1
        
    }
}

/* This code has been added in response to student comments */
extension LoginViewController {
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if keyboardAdjusted == false {
            lastKeyboardOffset = getKeyboardHeight(notification) / 2
            self.view.superview?.frame.origin.y -= lastKeyboardOffset
            keyboardAdjusted = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if keyboardAdjusted == true {
            self.view.superview?.frame.origin.y += lastKeyboardOffset
            keyboardAdjusted = false
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
}
