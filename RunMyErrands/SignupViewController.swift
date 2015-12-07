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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chooseProfilePicture(sender: UIButton) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .PhotoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func createNewUser(sender: UIButton) {
        if usernameTextField.text != "" && passwordTextField.text != ""  {
            let user  = PFUser()
            
            user.username = usernameTextField.text
            user.password = passwordTextField.text
            user["name"] = usernameTextField.text
            
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, error: NSError?) -> Void in
                if let error = error {
                    print("Error: \(error)")
                } else {
                    self.saveImage(user)
                }
            }
        } else {
            
        }
    }

    func saveImage(user: PFUser) {

            if let image = self.profileImage.image,
                let imageData = UIImageJPEGRepresentation(image, 0.25),
                let imageFile = PFFile(name:"profile.jpg", data:imageData) {
                    
                    imageFile.saveInBackgroundWithBlock({ (bool: Bool, error:NSError?) -> Void in
                        
                        if bool {
                            user["profile_Picture"] = imageFile
                            user.saveInBackgroundWithBlock({ (Bool, ErrorType) -> Void in
                                if (Bool) {
                                    print("save")
                                } else {
                                    print("failed saving profile picture")
                                }
                                self.performSegueWithIdentifier("showSignupToTabBar", sender: nil)
                            })
                        }
                    })
            }
    }
    
    @IBAction func cancel(sender: UIButton) {
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // The info dictionary contains multiple representations of the image, and this uses the original.
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        self.profileImage.image = selectedImage
        
        // Dismiss the picker.
        self.chooseProfilePicButton.hidden = true
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
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
