//
//  MapTasks.swift
//  RunMyErrands2Maps
//
//  Created by Steele on 2015-11-30.
//  Copyright © 2015 Steele. All rights reserved.
//

import UIKit
import GoogleMaps

enum TravelModes: Int {
    case driving
    case walking
    case bicycling
}

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
    
    func requestDirections(origin: CLLocationCoordinate2D!, destination: CLLocationCoordinate2D!, taskWaypoints: Array<GMSMarker>!, travelMode: TravelModes!, completionHandler: (sucess: Bool) ->()) {
        
        if let originLocation = origin {
            let originString = "\(originLocation.latitude),\(originLocation.longitude)"
            
            if let destinationLocation = destination {
                let destinationString = "\(destinationLocation.latitude),\(destinationLocation.longitude)"
                
                
                var directionsURLString = baseURLDirections + "origin=" + originString + "&destination=" + destinationString
                
                if let routeWaypoints = taskWaypoints {
                    directionsURLString += "&waypoints=optimize:true"
                    
                    for waypoint in routeWaypoints {
                        
                        let waypointString = "\(waypoint.position.latitude),\(waypoint.position.longitude)"
                        
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
                
                //print("url \(directionsURL)")
                
                let task = NSURLSession.sharedSession().dataTaskWithURL(directionsURL!) { (data, response, error) -> Void in
                    if(error != nil) {
                        print(error)
                    }
                    
                    let dictionary = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as? [String : AnyObject]
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        let status = dictionary!["status"] as! String
                        
                        //Cheak to see if google returned good data.
                        if status == "OK" {
                            
                            self.processDirections(dictionary!)
                            self.calculateTotalDistanceAndDuration(dictionary!)
                            completionHandler(sucess: true)
                        }
                        
                        print("dict \(dictionary)")
                    })
                }
                task.resume()
            }
        }
    }
    
    
    //convert JSON to directions
    func processDirections(directions: Dictionary<NSObject, AnyObject>) {
        guard let selected = (directions["routes"] as? Array<Dictionary<NSObject, AnyObject>>)?.first else {
            print("no first directions object")
            return
        }
        
        self.selectedRoute = selected
        
        self.overviewPolyline = self.selectedRoute["overview_polyline"] as! Dictionary<NSObject, AnyObject>
        
        let legs = self.selectedRoute["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        
        let startLocationDictionary = legs[0]["start_location"] as! Dictionary<NSObject, AnyObject>
        self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
        
        let endLocationDictionary = legs[legs.count - 1]["end_location"] as! Dictionary<NSObject, AnyObject>
        self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
        
        self.originAddress = legs[0]["start_address"] as! String
        self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
        
    }
    
    func legPolyline(legNumber: Int) -> [GMSPolyline] {
        
        var routes:[GMSPolyline] = [GMSPolyline]()
        let legs = self.selectedRoute["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        
        if legNumber < legs.count {
            
            let steps = legs[legNumber]["steps"] as! Array<Dictionary<NSObject, AnyObject>>
            
            for step in steps {
                
                let polyline = step["polyline"] as! Dictionary<NSObject, AnyObject>
                let points = polyline["points"] as! String
                
                let path: GMSPath = GMSPath(fromEncodedPath: points)
                let routePolyline1 = GMSPolyline(path: path)
                routePolyline1.strokeWidth = 2.0
                routePolyline1.strokeColor = UIColor.greenColor()
                
                routes += [routePolyline1]
            }
        }
        return routes
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
        
        totalTravelDuration = "Travel Duration: \(travelHours) hours, \(remainingTravelMins) mins"
        
        let errandsMins = totalErrandsInSeconds / 60
        let errandsHours = errandsMins / 60
        let remainingErrandsMins = errandsMins % 60
        
        totalErrandDuration = "Errands Duration: \(errandsHours) hours, \(remainingErrandsMins) mins"
        
        let totalMins = travelMins + errandsMins
        let hours = totalMins / 60
        let mins =  totalMins % 60
        
        totalDuration = "Approx. Total Duration: \(hours) hours, \(mins) mins"
    }
    
    
    //zoom the map to the limits of the tasks
    func zoomMapLimits(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, markerArray: [GMSMarker]) -> GMSCoordinateBounds {
        
        var minLat = 0.0
        var minLong = 0.0
        var maxLat = 0.0
        var maxLong = 0.0
        
        var northEast = CLLocationCoordinate2DMake(maxLat, maxLong)
        var southWest = CLLocationCoordinate2DMake(minLat, minLong)
        
        minLat = origin.latitude
        maxLat = origin.latitude
        
        minLong = origin.longitude
        maxLong = origin.longitude
        
        //add destination to bounds
        if destination.latitude < minLat {
            minLat = destination.latitude
        }
        if destination.latitude > maxLat {
            maxLat = destination.latitude
        }
        if destination.longitude < minLong {
            minLong = destination.longitude
        }
        if destination.longitude > maxLong {
            maxLong = destination.longitude
        }
        
        
        for marker in markerArray {
            
            if marker.position.latitude < minLat {
                minLat = marker.position.latitude
            }
            
            if marker.position.latitude > maxLat {
                maxLat = marker.position.latitude
            }
            
            if marker.position.longitude < minLong {
                minLong = marker.position.longitude
            }
            
            if marker.position.longitude > maxLong {
                maxLong = marker.position.longitude
            }
        }
        
        northEast = CLLocationCoordinate2DMake(maxLat, maxLong)
        southWest = CLLocationCoordinate2DMake(minLat, minLong)

        
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        
        return bounds
    }
    
    
    func HomeAddressValid(completion: (result: Bool) -> Void) {
        
        let user = PFUser.currentUser()
        if let homeAddress = user!["home"] {
            
            let destinationAddress = homeAddress as! String
            
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(destinationAddress, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                
                if let _ = placemarks?[0] {
                    completion(result: true)
                }else {
                    completion(result: false)
                }
            })
        }else {
            completion(result: false)
        }
    }

    
    
    
    
    
    
}
