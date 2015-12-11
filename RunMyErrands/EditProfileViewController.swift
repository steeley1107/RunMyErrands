
//
//  EditProfileViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-10.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var statusTextField: UITextField!
    
    @IBOutlet weak var addressTextField: UITextField!
    
    var user: PFUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        user = PFUser.currentUser()
        nameTextField.text = user!["name"] as? String
        statusTextField.text = user!["status"] as? String
        addressTextField.text = user!["home"] as? String
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editProfile(sender: UIButton) {
        
        user!["name"] = nameTextField.text
        user!["status"] = statusTextField.text
        user!["home"] = addressTextField.text
        
        user?.saveInBackground()
        
        self.navigationController?.popViewControllerAnimated(true)
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
