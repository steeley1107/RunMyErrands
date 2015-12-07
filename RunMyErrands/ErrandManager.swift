//
//  ErrandManager.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-04.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

//import UIKit
import Foundation
import Parse

@objc class ErrandManager: NSObject {
    
    private var errandsDictionary:NSMutableDictionary!
    
    private var objectIDtoNameDictionary:NSMutableDictionary!
    
    private let user:PFUser!
    
    override init() {
        errandsDictionary = NSMutableDictionary()
        user = PFUser.currentUser()
        objectIDtoNameDictionary = NSMutableDictionary()
    }
    
    func fetchData(tableView: UITableView) {
        let relation = self.user.relationForKey("memberOfTheseGroups")
        
        relation.query().orderByAscending("name").findObjectsInBackgroundWithBlock { (objects:[PFObject]?, error: NSError?) -> Void in
            
            if let objects = objects {
                
                for group in objects {
                    print(group["name"])
                    
                    //self.groupNameToObjectIDDictionary.setValue(group.objectId, forKey: group["name"] as! String)
                    //self.groupNames.insert(group["name"] as! String, atIndex: self.groupNames.endIndex)
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    
                    let errandsForGroupRelation = group.relationForKey("errands")
                    errandsForGroupRelation.query().findObjectsInBackgroundWithBlock({ (errands:[PFObject]?, error:NSError?) -> Void in
                        let errandsArray = errands as! [Task]
                        
                        self.errandsDictionary.setValue(errandsArray, forKey: group.objectId!)
                        tableView.reloadData()
                    })
                }
                
            }
        }
    }
    
    func fetchNumberOfGroups() -> Int {
        return self.errandsDictionary.allKeys.count
    }
    
    func fetchErrandsForGroup(section: NSInteger) -> [Task]? {
        
        if let groups = self.errandsDictionary.allKeys as? [String] {
            let group = groups[section]
            return self.errandsDictionary.valueForKey(group) as? [Task]
        } else {
            return nil
        }
    }
    
    func fetchNumberOfRowsInSection(section: NSInteger) -> Int {
        if let errands = fetchErrandsForGroup(section) {
            return errands.count
        } else {
            return 0
        }
    }
    
    
    func fetchErrand(indexPath: NSIndexPath) -> Task? {
        if let errands = fetchErrandsForGroup(indexPath.section) {
            return errands[indexPath.row]
        } else {
            return nil
        }
    }
    
    func fetchTitleForHeaderInSection(section: NSInteger) -> String? {
        
        if let groups = self.errandsDictionary.allKeys as? [String] {
            let gObjectID = groups[section]
            let gName = self.objectIDtoNameDictionary.valueForKey(gObjectID) as! String
            return gName.capitalizedString
        } else {
            return nil
        }
    }
    
    
    func fetchDataNew(completionHandler: (sucess: Bool) ->() ) {
        let relation = self.user.relationForKey("memberOfTheseGroups")
        
        relation.query().orderByAscending("name").findObjectsInBackgroundWithBlock { (objects:[PFObject]?, error: NSError?) -> Void in
            
            if let objects = objects {
                
                for group in objects {
                    print(group["name"])
                    
                    //self.groupNameToObjectIDDictionary.setValue(group.objectId, forKey: group["name"] as! String)
                    //self.groupNames.insert(group["name"] as! String, atIndex: self.groupNames.endIndex)
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    
                    let errandsForGroupRelation = group.relationForKey("errands")
                    errandsForGroupRelation.query().findObjectsInBackgroundWithBlock({ (errands:[PFObject]?, error:NSError?) -> Void in
                        let errandsArray = errands as! [Task]
                        
                        self.errandsDictionary.setValue(errandsArray, forKey: group.objectId!)
                        completionHandler(sucess: true)
                    })
                }
                
            } else {
                
                completionHandler(sucess: true)
            }
        }
    }
    
    




















}
