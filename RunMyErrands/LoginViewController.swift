//  LoginViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-30.
//  Copyright © 2015 Jeff Mew. All rights reserved.


import Foundation
import UIKit
import ParseFacebookUtilsV4
import FBSDKCoreKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        if (PFUser.current() != nil) {
            self.performSegue(withIdentifier: "showErrandList", sender: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    @IBAction func login(_ sender: UIButton) {
        
        if let username = usernameTextField.text,
            let password = passwordTextField.text {
                PFUser.logInWithUsername(inBackground: username.lowercased(), password:password) {
                    (user: PFUser?, error: Error?) -> Void in
                    if user != nil {
                        // Go to next storyboard
                        self.performSegue(withIdentifier: "showErrandList", sender: nil)
                    } else {
                        // Shake screen to indicate invalid login
                        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
                        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                        animation.duration = 0.5
                        animation.values = [-20,20,-20,20,-10,10,-5,5,0]                    
                        self.stackView.layer.add(animation, forKey: "transform.translation.x")
                    }
                }
        }
    }

    @IBAction func twitterLogin(_ sender: UIButton) {
        
    }
    
    @IBAction func facebookLogin(_ sender: UIButton) {

        let permissions = ["public_profile","user_friends"]
        
        PFFacebookUtils.logInInBackground(withReadPermissions: permissions) {
            (user: PFUser?, error: Error?) -> Void in
            if let user = user {
                
                if user.isNew
                {
                    user["status"] = ""
                    user["pushNotify"] = true
                    user["totalErrandsCompleted"] = 0
                    user["geoRadius"] = 200
                    self.getNameAndPicture(user)                    
                }
                else
                {
                    self.performSegue(withIdentifier: "showErrandList", sender: nil)
                }
            }
            else
            {
                print("Uh oh. The user cancelled the Facebook login.")
            }
        }
    }
    
    func getNameAndPicture(_ user: PFUser) {
        print("User signed up and logged in through Facebook!")
        //first time user -> onboard
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me?fields=first_name,picture.type(large)", parameters: nil)
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(String(describing: error))")
            } else {
                print("fetched user: \(String(describing: result))")

                
                let data:[String:AnyObject] = result as! [String : AnyObject]
                if let name = data["first_name"] {
                    user["name"] = name
                    print("name is: \(name)")
                }

                let userInfo = result as? [String: Any]
                if let url = ((userInfo?["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String {
                                        
                    let session = URLSession.shared.dataTask(with: URL.init(string: url)!, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                        if error != nil {
                            print("Error: \(String(describing: error))")
                        } else {
                            if let data = data,
                                let imageFile = PFFile(name: "profile.jpg", data: data) {
                                    imageFile.saveInBackground(block: { (bool:Bool, error:Error?) -> Void in
                                        if bool {
                                            user["profile_Picture"] = imageFile
                                            
                                            user.saveInBackground(block: { (success:Bool, error: Error?) -> Void in
                                                if ((error) != nil) {
                                                    print("Error: \(String(describing: error))")
                                                }
                                                print("User logged in through Facebook!")
                                                self.performSegue(withIdentifier: "showErrandList", sender: nil)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
}
