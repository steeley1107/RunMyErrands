//
//  CreateNewGroupViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import Parse

class CreateNewGroupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var newGroupNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func createNewGroup(_ sender: UIButton) {
        
        if let newGroupName = self.newGroupNameTextField.text,
            let currentUser = PFUser.current() {
                
            let newGroup = PFObject(className: "Group")

            newGroup["name"] = newGroupName
            newGroup["teamLeader"] = currentUser.objectId
            
            let memberRelation = newGroup.relation(forKey: "groupMembers")
            
            memberRelation.add(currentUser)
            
            newGroup.saveInBackground(block: { (bool: Bool, error: Error?) -> Void in
                
                let groupRelation = currentUser.relation(forKey: "memberOfTheseGroups")
                groupRelation.add(newGroup)
                currentUser.saveInBackground(block: { (bool:Bool, error:Error?) -> Void in
                    //
                    self.dismiss(animated: true, completion: nil)
                })
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
