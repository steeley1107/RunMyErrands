//
//  JoinGroupViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-02.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import Parse

class JoinGroupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var groupIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func joinGroup(_ sender: UIButton) {
        if let groupID = groupIDTextField.text {
            
            let query = PFQuery(className: "Group")
            query.getObjectInBackground(withId: groupID, block: { (object: PFObject?, error: NSError?) -> Void in
                if (error != nil) {
                    print("Error: \(error)")
                } else {
                    //object is a 'Group'
                    if let currentUser = PFUser.current(),
                        let object = object {
                        
                        let memberRelation = object.relation(forKey: "groupMembers")
                        memberRelation.add(currentUser)
                        object.saveInBackground(block: { (bool: Bool, error: NSError?) -> Void in
                            
                            let groupRelation = currentUser.relation(forKey: "memberOfTheseGroups")
                            groupRelation.add(object)
                            currentUser.saveInBackground(block: { (bool:Bool, error: NSError?) -> Void in
                                
                                //New Push Notifications with cloud code
                                let setChannel = groupID
                                let setMessage = "\((currentUser["name"] as AnyObject).capitalized) has joined your '\((object["name"] as AnyObject).capitalized)' group."
                                
                                PFCloud.callFunction(inBackground: "iosPush", withParameters: ["channels": setChannel, "message":setMessage]) { (response, error) -> Void in
                                }
                                
                                
                                self.dismiss(animated: true, completion: nil)
                            } as! PFBooleanResultBlock)
                        } as! PFBooleanResultBlock)
                    }
                }
            } as! (PFObject?, Error?) -> Void)
        }
    }
    
    
    @IBAction func cancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil);
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
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
