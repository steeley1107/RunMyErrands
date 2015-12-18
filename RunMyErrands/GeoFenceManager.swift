//
//  GeoFenceManager.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-18.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import Foundation
import Parse

class GeoFenceManager: NSObject {
    
    
    //Mark: Properties
    var locationManager: GeoManager!
    var errandsManager = ErrandManager()
    
    
    func CreateGeoPoint() {
        
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for var index in 0..<numberOfGroups {
                    
                    if let groupTaskArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for task in groupTaskArray {
                            
                            task.geoPoint = PFGeoPoint(latitude:task.lattitude.doubleValue, longitude:task.longitude.doubleValue)
                            task.saveInBackground()
                        }
                    }
                }
            } else {
                print("problem creating geoPoints")
            }
            //
        }
    }
    
    
    func GetClosestErrands() {
        
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                
                var closestErrandsArray = [Task]()
                
                // User's location
                if let userGeoPoint = geoPoint {
                    // Create a query for places
                    let query = PFQuery(className:"Task")
                    query.whereKey("group", containedIn: self.errandsManager.fetchKeys())
                    query.whereKey("isComplete", equalTo: false)
                    query.whereKey("geoPoint", nearGeoPoint:userGeoPoint)
                    // Limit 20 of the closest errands
                    query.limit = 20
                    
                    query.findObjectsInBackgroundWithBlock({
                        (objects, error) in
                        if error == nil {
                            print("objects \(objects)")
                            closestErrandsArray = objects as! [Task]
                            if closestErrandsArray.count != 0 {
                                self.trackGeoRegions(closestErrandsArray)
                            }
                        }
                    })
                }
            }
        }
    }
    
    
    
    func trackGeoRegions(errandsArray: [Task]) {
        
        locationManager.removeAllTaskLocation()
        for task in errandsArray {
            
            if task.isComplete.boolValue == false {
                
                let center = task.coordinate()
                let taskRegion = CLCircularRegion.init(center: center, radius: 200.0, identifier: "\(task.title) \n \(task.subtitle)")
                taskRegion.notifyOnEntry = true
                locationManager.addTaskLocation(taskRegion)
            }
        }
    }
    
    
    
    
}
