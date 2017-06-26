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
    
    fileprivate var errandsDictionary:NSMutableDictionary!
    
    fileprivate var objectIDtoNameDictionary:NSMutableDictionary!
    
    fileprivate let user:PFUser!
    
    override init() {
        errandsDictionary = NSMutableDictionary()
        user = PFUser.current()
        objectIDtoNameDictionary = NSMutableDictionary()
    }
    
    func fetchNumberOfGroups() -> Int {
        return self.errandsDictionary.allKeys.count
    }
    
    func fetchErrandsForGroup(_ section: NSInteger) -> [Errand]? {
        
        if let groups = self.errandsDictionary.allKeys as? [String] {
            let group = groups[section]
            return self.errandsDictionary.valueForKey(group) as? [Errand]
        } else {
            return nil
        }
    }
    
    func fetchNumberOfRowsInSection(_ section: NSInteger) -> Int {
        if let errands = fetchErrandsForGroup(section) {
            return errands.count
        } else {
            return 0
        }
    }
    
    
    func fetchErrand(_ indexPath: NSIndexPath) -> Errand? {
        if let errands = fetchErrandsForGroup(indexPath.section) {
            return errands[indexPath.row]
        } else {
            return nil
        }
    }
    
    func fetchTitleForHeaderInSection(_ section: NSInteger) -> String? {
        
        if let groups = self.errandsDictionary.allKeys as? [String] {
            let gObjectID = groups[section]
            let gName = self.objectIDtoNameDictionary.value(forKey: gObjectID) as! String
            return gName.capitalized
        } else {
            return nil
        }
    }
    
    func clearData() {
        self.errandsDictionary.removeAllObjects()
        self.objectIDtoNameDictionary.removeAllObjects()
    }
    
    func fetchData(_ completionHandler: @escaping (_ success: Bool) ->() ) {
        let relation = self.user.relation(forKey: "memberOfTheseGroups")
        relation.query().order(byAscending: "name").findObjectsInBackground { (objects: [PFObject]?, error: NSError?) -> Void in
            self.clearData()
            if let objects = objects {
                for group in objects {
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    self.errandsDictionary.setValue([], forKey: group.objectId!)
                }
                
                let errandsQuery = PFQuery(className: "Errand")
                errandsQuery.whereKey("group", containedIn: self.fetchKeys())
                errandsQuery.order(byAscending: "isComplete")
                errandsQuery.findObjectsInBackground(block: { (errands: [PFObject]?, error: NSError?) -> Void in
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
        } as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void
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
    
    func fetchIncompleteErrand(_ completionHandler: @escaping (_ success: Bool) ->() ) {
        let relation = self.user.relation(forKey: "memberOfTheseGroups")
        relation.query().order(byAscending: "name").findObjectsInBackground { (objects: [PFObject]?, error: NSError?) -> Void in
            if let objects = objects {
                for group in objects {
                    self.objectIDtoNameDictionary.setValue(group["name"] as! String, forKey: group.objectId!)
                    self.errandsDictionary.setValue([], forKey: group.objectId!)
                }
                
                let errandsQuery = PFQuery(className: "Errand")
                errandsQuery.whereKey("group", containedIn: self.fetchKeys())
                errandsQuery.whereKey("isComplete", equalTo: false)
                errandsQuery.findObjectsInBackground(block: { (errands: [PFObject]?, error: NSError?) -> Void in
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
        } as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void as! ([PFObject]?, Error?) -> Void
    }
    
    
}










