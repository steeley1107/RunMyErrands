//
//  Scheduler.swift
//  RunMyErrands
//
//  Created by Steele on 2016-01-05.
//  Copyright © 2016 Jeff Mew. All rights reserved.
//

import UIKit

class Scheduler: NSObject {
    
    //Mark: Properties
    var errandsManager = ErrandManager()
    var currentDateTime = NSDate()
    let calendar = NSCalendar.currentCalendar()
    var activeErrandsExpiryDuration = 12
    var completedErrandsExpiryDuration = 1
    
    
    
    //Mark: Functions
    
    //check errands to see if they have expired.
    func CheckActiveErrandsExpiry() {
        
        //fetch errands from Parse
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandsArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for errand in groupErrandsArray {
                            
                            //reset expired errands.
                            if errand.activeDate != nil && errand.activeDate.timeIntervalSinceNow < 0 {
                                
                                errand.isActive = false
                                errand.activeDate = nil
                                errand.saveInBackground()
                            }
                        }
                    }
                }
            } else {
                print("problem reseting expired active errands")
            }
        }
    }
    
    
    //check errands to see if they have expired.
    func CheckCompletedErrandsExpiry() {
        
        //fetch errands from Parse
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandsArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for errand in groupErrandsArray {
                            
                            //reset expired errands.
                            if errand.completedDate != nil && errand.completedDate.timeIntervalSinceNow < 0 {
                                
                                errand.deleteInBackground()
                            }
                        }
                    }
                }
            } else {
                print("problem reseting expired active errands")
            }
        }
    }
    
    //functions not currenly being used. Might be required if errands are not being removed.
    
    //add erpiry time to active errands.
    func CreateActiveErrandsExpiryDate() {
        
        let expiryActiveDate = calendar.dateByAddingUnit(.Hour, value: activeErrandsExpiryDuration, toDate: currentDateTime, options: [])
        
        //fetch errands from Parse
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandsArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for errand in groupErrandsArray {
                            
                            //add expiry time to active errands
                            if errand.isActive == true && errand.activeDate == nil {
                                
                                errand.activeDate = expiryActiveDate
                                errand.saveInBackground()
                            }
                        }
                    }
                }
            } else {
                print("problem creating active date")
            }
        }
    }
    
    
    //add erpiry time to active errands.
    func CreateCompletedErrandsExpiryDate() {
        
        let expiryCompletedDate = calendar.dateByAddingUnit(.Day, value: completedErrandsExpiryDuration, toDate: currentDateTime, options: [])
        
        //fetch errands from Parse
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandsArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for errand in groupErrandsArray {
                            
                            //add expiry time to active errands
                            if errand.isComplete == true && errand.completedDate == nil {
                                
                                errand.completedDate = expiryCompletedDate
                                errand.saveInBackground()
                            }
                        }
                    }
                }
            } else {
                print("problem creating active date")
            }
        }
    }

    
    
    
}
