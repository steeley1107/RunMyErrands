//
//  CreateNewGroupViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import Parse

class CreateNewGroupViewController: UIViewController {

    @IBOutlet weak var newGroupNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func createNewGroup(sender: UIButton) {
        
        if let newGroupName = self.newGroupNameTextField.text,
            let currentUser = PFUser.currentUser() {
                
            let newGroup = PFObject(className: "Group")

            newGroup["name"] = newGroupName
            newGroup["teamLeader"] = currentUser.objectId
            
            let memberRelation = newGroup.relationForKey("groupMembers")
            
            memberRelation.addObject(currentUser)
            
            newGroup.saveInBackgroundWithBlock({ (bool: Bool, error: NSError?) -> Void in
                
                let groupRelation = currentUser.relationForKey("memberOfTheseGroups")
                groupRelation.addObject(newGroup)
                currentUser.saveInBackgroundWithBlock({ (bool:Bool, error:NSError?) -> Void in
                    //
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            })
        }
    }
    
    
    @IBAction func cancel(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
