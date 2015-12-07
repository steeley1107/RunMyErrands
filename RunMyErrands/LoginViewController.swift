//  LoginViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-30.
//  Copyright © 2015 Jeff Mew. All rights reserved.


import Foundation
import UIKit
import ParseFacebookUtilsV4
import FBSDKCoreKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBAction func login(sender: UIButton) {
        
        if let username = usernameTextField.text,
            password = passwordTextField.text {
                PFUser.logInWithUsernameInBackground(username, password:password) {
                    (user: PFUser?, error: NSError?) -> Void in
                    if user != nil {
                        // Do stuff after successful login.
                        self.performSegueWithIdentifier("showErrandList", sender: nil)
                    } else {
                        // The login failed. Check error to see why.
                    }
                }
        }
    }
    
    @IBAction func twitterLogin(sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    @IBAction func facebookLogin(sender: UIButton) {

        let permissions = ["public_profile","user_friends"]
        
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                
                if user.isNew {
                    self.getNameAndPicture(user)
                } else {
                    print("User logged in through Facebook!")
                    
                    self.performSegueWithIdentifier("showErrandList", sender: nil)
                }
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
            }
        }
    }
    
    func getNameAndPicture(user: PFUser) {
        print("User signed up and logged in through Facebook!")
        //first time user -> onboard
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me?fields=first_name,picture.type(large)", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
            } else {
                print("fetched user: \(result)")

                if let name = result.valueForKey("first_name") as? String {
                    user["name"] = name
                    print("name is: \(name)")
                }

                if let url = result.valueForKey("picture")?.valueForKey("data")?.valueForKey("url") as? String {
                                        
                    let session = NSURLSession.sharedSession().dataTaskWithURL(NSURL.init(string: url)!, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                        if error != nil {
                            print("Error: \(error)")
                        } else {
                            if let data = data,
                                let imageFile = PFFile(name: "profile.jpg", data: data) {
                                    imageFile.saveInBackgroundWithBlock({ (bool:Bool, error:NSError?) -> Void in
                                        if bool {
                                            user["profile_Picture"] = imageFile
                                            
                                            user.saveInBackgroundWithBlock({ (success:Bool, error: NSError?) -> Void in
                                                if ((error) != nil) {
                                                    print("Error: \(error)")
                                                }
                                                print("User logged in through Facebook!")
                                                self.performSegueWithIdentifier("showErrandList", sender: nil)
                                            })
                                        }
                                    })
                            }
                        }
                    })
                    session.resume()
                }
            }
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
}