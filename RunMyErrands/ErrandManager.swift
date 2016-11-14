//
//  ErrandManager.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-04.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

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
    
    func fetchNumberOfGroups() -> Int {
        return self.errandsDictionary.allKeys.count
    }
    
    func fetchErrandsForGroup(section: NSInteger) -> [Errand]? {
        
        if let groups = self.errandsDictionary.allKeys as? [String] {
            let group = groups[section]
            return self.errandsDictionary.valueForKey(group) as? [Errand]
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
    
    
    func fetchErrand(indexPath: NSIndexPath) -> Errand? {
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
    
    func clearData() {
        self.errandsDictionary.removeAllObjects()
        self.objectIDtoNameDictionary.removeAllObjects()
    }
    
    func fetchData(completionHandler: (success: Bool) ->() ) {
        let relation = self.user.relationForKey("memberOfTheseGroups")
        relation.query().orderByAscending("name").findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            self.clearData()
            if let objects = objects {
                for group in objects {
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    self.errandsDictionary.setValue([], forKey: group.objectId!)
                }
                
                let errandsQuery = PFQuery(className: "Errand")
                errandsQuery.whereKey("group", containedIn: self.fetchKeys())
                errandsQuery.orderByAscending("isComplete")
                errandsQuery.findObjectsInBackgroundWithBlock({ (errands: [PFObject]?, error: NSError?) -> Void in
                    if error == nil {
                        if let errands = errands as? [Errand] {
                            for errand in errands {
                                var errandArray:Array = self.errandsDictionary.objectForKey(errand.group!) as! [Errand]
                                errandArray.append(errand)
                                self.errandsDictionary.setValue(errandArray, forKey: errand.group!)
                            }
                            completionHandler(success: true)
                        }
                    } else {
                        completionHandler(success: false)
                    }
                })
            } else {
                completionHandler(success: false)
            }
        }
    }
    
    func fetchKeys() -> [String] {
        return self.objectIDtoNameDictionary.allKeys as! [String]
    }
    
    func isEmpty() -> Bool {
        if self.errandsDictionary.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func fetchIncompleteErrand(completionHandler: (success: Bool) ->() ) {
        let relation = self.user.relationForKey("memberOfTheseGroups")
        relation.query().orderByAscending("name").findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            if let objects = objects {
                for group in objects {
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    self.errandsDictionary.setValue([], forKey: group.objectId!)
                }
                
                let errandsQuery = PFQuery(className: "Errand")
                errandsQuery.whereKey("group", containedIn: self.fetchKeys())
                errandsQuery.whereKey("isComplete", equalTo: false)
                errandsQuery.findObjectsInBackgroundWithBlock({ (errands: [PFObject]?, error: NSError?) -> Void in
                    if error == nil {
                        if let errands = errands as? [Errand] {
                            for errand in errands {
                                var errandArray:Array = self.errandsDictionary.objectForKey(errand.group!) as! [Errand]
                                errandArray.append(errand)
                                self.errandsDictionary.setValue(errandArray, forKey: errand.group!)
                            }
                            completionHandler(success: true)
                        }
                    } else {
                        completionHandler(success: false)
                    }
                })
            } else {
                completionHandler(success: false)
            }
        }
    }
    
    
}










