//
//  SignupViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import Parse

class SignupViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var chooseProfilePicButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackHeight: NSLayoutConstraint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        //Subscribe to events to move textfields up/down when keyboard appears/disappears
        NotificationCenter.default.addObserver(self, selector: #selector(SignupViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignupViewController.keybaordDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chooseProfilePicture(_ sender: UIButton) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func createNewUser(_ sender: UIButton) {
        
        guard self.confirmPasswordTextField.text == self.passwordTextField.text else {
            let alertController = UIAlertController(title: "Error", message: "Passwords Must Be The Same", preferredStyle: UIAlertControllerStyle.alert)
            
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alertController.addAction(ok)
            
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        if usernameTextField.text != "" && passwordTextField.text != ""  {
            let user  = PFUser()
            
            user.username = usernameTextField.text?.lowercased()
            user.password = passwordTextField.text
            user["name"] = usernameTextField.text
            user["status"] = ""
            user["pushNotify"] = true
            user["totalErrandsCompleted"] = 0
            user["geoRadius"] = 200
            
            //check if username already exists
            let query = PFUser.query()
            
            query?.whereKey("username", equalTo: user.username!)
            
            query?.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) -> Void in
                
                if (error == nil) {
                    
                    if let objects = objects {
                        print("object count = \(objects.count)")
                        if objects.count > 0 {
                            let alertController = UIAlertController(title: "Error", message: "Username Already Exists", preferredStyle: UIAlertControllerStyle.alert)
                            
                            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                            alertController.addAction(ok)
                            
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            user.signUpInBackground {
                                (succeeded: Bool, error: Error?) -> Void in
                                if let error = error {
                                    print("Error: \(error)")
                                } else {
                                    self.saveImage(user)
                                }
                            }
                        }
                    }
                } else {
                    print("Error: \(String(describing: error))")
                }
            })
            
        } else {
            let alertController = UIAlertController(title: "Error", message: "Invalid Username/Password", preferredStyle: UIAlertControllerStyle.alert)
            
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alertController.addAction(ok)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func saveImage(_ user: PFUser) {

            if let image = self.profileImage.image,
                let imageData = UIImageJPEGRepresentation(image, 0.25),
                let imageFile = PFFile(name:"profile.jpg", data:imageData) {
                    
                    imageFile.saveInBackground(block: { (bool: Bool, error:Error?) -> Void in
                        
                        if bool {
                            user["profile_Picture"] = imageFile
                            user.saveInBackground(block: { (Bool, ErrorType) -> Void in
                                if (Bool) {
                                    print("save")
                                } else {
                                    print("failed saving profile picture")
                                }
                                self.performSegue(withIdentifier: "onboard", sender: nil)
                            })
                        } else {
                            self.performSegue(withIdentifier: "onboard", sender: nil)
                        }
                    })
            } else {
              self.performSegue(withIdentifier: "onboard", sender: nil)
            }
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary contains multiple representations of the image, and this uses the original.
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        self.profileImage.image = selectedImage
        
        // Dismiss the picker.
        self.chooseProfilePicButton.isHidden = true
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    
    func keyboardDidShow(_ notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.stackHeight.constant = -(keyboardFrame.size.height + 20)
        })
    }
    
    func keybaordDidHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.stackHeight.constant = 0
        })
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
