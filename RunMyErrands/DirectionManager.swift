//
//  MapTasks.swift
//  RunMyErrands2Maps
//
//  Created by Steele on 2015-11-30.
//  Copyright © 2015 Steele. All rights reserved.
//

import UIKit
import GoogleMaps

class DirectionManager: NSObject {
    
    
    //Mark: Properties
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    var selectedRoute: Dictionary<NSObject, AnyObject>!
    var waypointOrder: Array<Int>!
    var overviewPolyline: Dictionary<NSObject, AnyObject>!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalTravelDurationInSeconds: UInt = 0
    var totalTravelDuration: String!
    var errandDuration: UInt = 1200 //20 mins
    var totalErrandDuration: String!
    var totalErrandsInSeconds: UInt = 0
    var totalDuration: String!
    var totalDurationInSeconds: UInt = 0
    
    
    //Request Directions from Google.
    
    func requestDirections(origin: CLLocationCoordinate2D!, taskWaypoints: Array<Task>!, travelMode: TravelModes!, completionHandler: (sucess: Bool) ->()) {
        
        if let originLocation = origin {
            let originString = "\(originLocation.latitude),\(originLocation.longitude)"
            
            var directionsURLString = baseURLDirections + "origin=" + originString + "&destination=" + originString
            
            if let routeWaypoints = taskWaypoints {
                directionsURLString += "&waypoints=optimize:true"
                
                for waypoint in routeWaypoints {
                    
                    let waypointString = "\(waypoint.lattitude),\(waypoint.longitude)"
                    
                    directionsURLString += "|" + waypointString
                }
            }
            
            if let travel = travelMode {
                var travelModeString = ""
                
                switch travel.rawValue {
                case TravelModes.walking.rawValue:
                    travelModeString = "walking"
                    
                case TravelModes.bicycling.rawValue:
                    travelModeString = "bicycling"
                    
                default:
                    travelModeString = "driving"
                }
                
                directionsURLString += "&mode=" + travelModeString
            }
            
            directionsURLString = directionsURLString.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())!
            
            let directionsURL = NSURL(string: directionsURLString)
            
            let task = NSURLSession.sharedSession().dataTaskWithURL(directionsURL!) { (data, response, error) -> Void in
                if(error != nil) {
                    print(error)
                }
                
                let dictionary = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as? [String : AnyObject]
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("dict \(dictionary)")
                    self.processDirections(dictionary!)
                    self.calculateTotalDistanceAndDuration(dictionary!)
                    completionHandler(sucess: true)
                })
            }
            task.resume()
        }
    }
    
    
    //convert JSON to directions
    func processDirections(directions: Dictionary<NSObject, AnyObject>) {
        
        self.selectedRoute = (directions["routes"] as! Array<Dictionary<NSObject, AnyObject>>)[0]
        self.overviewPolyline = self.selectedRoute["overview_polyline"] as! Dictionary<NSObject, AnyObject>
        
        let legs = self.selectedRoute["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        
        let startLocationDictionary = legs[0]["start_location"] as! Dictionary<NSObject, AnyObject>
        self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
        
        let endLocationDictionary = legs[legs.count - 1]["end_location"] as! Dictionary<NSObject, AnyObject>
        self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
        
        self.originAddress = legs[0]["start_address"] as! String
        self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
        
    }
    
    
    //Calculate the duration and distance
    func calculateTotalDistanceAndDuration(directions: Dictionary<NSObject, AnyObject>) {
        
        let legs = self.selectedRoute["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        waypointOrder = self.selectedRoute["waypoint_order"] as! Array<Int>
        
        totalDistanceInMeters = 0
        totalTravelDurationInSeconds = 0
        totalErrandsInSeconds = 0
        totalDurationInSeconds = 0
        
        for leg in legs {
            totalDistanceInMeters += (leg["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
            totalTravelDurationInSeconds += (leg["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
        }
        
        totalErrandsInSeconds = (errandDuration * UInt(waypointOrder.count))
        
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        totalDistance = "Total Distance: \(distanceInKilometers) Km"
        
        
        let travelMins = totalTravelDurationInSeconds / 60
        let travelHours = travelMins / 60
        let remainingTravelMins = travelMins % 60
        let remainingTravelSecs = totalTravelDurationInSeconds % 60
        
        totalTravelDuration = "Travel Duration: \(travelHours) h, \(remainingTravelMins) mins, \(remainingTravelSecs) secs"
        
        let errandsMins = totalErrandsInSeconds / 60
        let errandsHours = errandsMins / 60
        let remainingErrandsMins = errandsMins % 60
        let remainingErrandsSecs = totalErrandsInSeconds % 60
        
        totalErrandDuration = "Errands Duration: \(errandsHours) h, \(remainingErrandsMins) mins, \(remainingErrandsSecs) secs"
        
        let hours = travelHours + errandsHours
        let mins =  remainingTravelMins + remainingErrandsMins
        let secs = remainingTravelSecs + remainingErrandsSecs
        
        totalDuration = "Approx. Total Duration: \(hours) h, \(mins) mins, \(secs) secs"
        
    }
    
    
}
