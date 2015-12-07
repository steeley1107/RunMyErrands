//
//  JoinGroupViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import Parse

class JoinGroupViewController: UIViewController {

    @IBOutlet weak var groupIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func joinGroup(sender: UIButton) {
        if let groupID = groupIDTextField.text {

            let query = PFQuery(className: "Group")
            query.getObjectInBackgroundWithId(groupID, block: { (object: PFObject?, error: NSError?) -> Void in
                if (error != nil) {
                    print("Error: \(error)")
                } else {
                    //object is a 'Group'
                    if let currentUser = PFUser.currentUser(),
                        let object = object {

                        let memberRelation = object.relationForKey("groupMembers")
                        memberRelation.addObject(currentUser)
                            object.saveInBackgroundWithBlock({ (bool: Bool, error: NSError?) -> Void in

                                let groupRelation = currentUser.relationForKey("memberOfTheseGroups")
                                groupRelation.addObject(object)
                                currentUser.saveInBackgroundWithBlock({ (bool:Bool, error: NSError?) -> Void in
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                })
                        })
                    }
                }
            })
        }
    }
    
    
    @IBAction func cancel(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil);
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
