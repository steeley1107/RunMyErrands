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
    
    //temp program
    func CreateGeoPoint() {
        
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for Errand in groupErrandArray {
                            
                            Errand.geoPoint = PFGeoPoint(latitude:Errand.lattitude.doubleValue, longitude:Errand.longitude.doubleValue)
                            Errand.saveInBackground()
                        }
                    }
                }
            } else {
                print("problem creating geoPoints")
            }
            //
        }
    }
    
    
    func GetDataForFence() {
        
        guard PFUser.current() != nil else {
            return
        }
        
        errandsManager.fetchData { (success) -> () in
            if success {
                self.GetClosestErrands()
                
            } else {
                print("problem creating geoPoints")
            }
        }
    }

    
    
    
    func GetClosestErrands() {
        
        PFGeoPoint.geoPointForCurrentLocation { (geoPoint, error) in
            if error == nil {
                
                var closestErrandsArray = [Errand]()
                
                // User's location
                if let userGeoPoint = geoPoint {
                    // Create a query for places
                    let query = PFQuery(className:"Errand")
                    query.whereKey("group", containedIn: self.errandsManager.fetchKeys())
                    query.whereKey("isComplete", equalTo: false)
                    query.whereKey("geoPoint", nearGeoPoint:userGeoPoint)
                    // Limit 20 of the closest errands
                    query.limit = 20
                    
                    query.findObjectsInBackground(block: {
                        (errands, error) in
                        if error == nil {
                            if let errands = errands as? [Errand] {
                                
                                for errand in errands {
                                    closestErrandsArray += [errand]
                                }
                                self.trackGeoRegions(closestErrandsArray)
                            }
                        }
                    })
                }
            }
        }
    }
    
    
    
    func trackGeoRegions(_ errandsArray: [Errand]) {

        locationManager = GeoManager.shared()
        locationManager.startLocationManager()

        locationManager.removeAllErrandLocation()
        
        let user = PFUser.current()
        var geoRadius:Double
        
        if let parseGeoRadius:Double = user!["geoRadius"] as? Double {
            geoRadius = parseGeoRadius
        } else {
            geoRadius = 200
        }
        
        for errand in errandsArray {
            
            if errand.isComplete.boolValue == false {
                
                let center = errand.coordinate()
                let ErrandRegion = CLCircularRegion.init(center: center, radius: geoRadius, identifier: "\(errand.title) \n \(errand.subtitle)")
                ErrandRegion.notifyOnEntry = true
                locationManager.addErrandLocation(ErrandRegion)
            }
        }
    }
    
    
    
    
}
