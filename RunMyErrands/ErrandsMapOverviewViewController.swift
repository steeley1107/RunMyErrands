//
//  ErrandsMapOverviewViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-06.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import GoogleMaps

class ErrandsMapOverviewViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    var locationManager: GeoManager!
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var taskArray:[Task] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = mapView.bounds
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        
        self.errandsManager = ErrandManager()
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        addMarkersToMap()
        populateTaskArray()
    }
    
    
    
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
        }
    }
    
    
    func addMarkersToMap() {
        
        errandsManager.fetchDataNew { (sucess) -> () in
            if sucess {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for var index in 0..<numberOfGroups {
                    
                    if let taskArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for task in taskArray {
                            
                            if task.isComplete == false {
                                
                                let marker = task.makeMarker()
                                marker.userData = task
                                marker.map = self.mapView
                                marker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func trackGeoRegions() {
        
        locationManager.removeAllTaskLocation()
        for task in taskArray {
            let center = task.coordinate()
            let taskRegion = CLCircularRegion.init(center: center, radius: 200.0, identifier: "\(task.title) \n \(task.subtitle)")
            
            taskRegion.notifyOnEntry = true
            if task.isComplete.boolValue == false {
                locationManager.addTaskLocation(taskRegion)
            }
        }
    }
    
    
    
    func populateTaskArray() {
        
        errandsManager.fetchDataNew { (sucess) -> () in
            if sucess {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for var index in 0..<numberOfGroups {
                    
                    if let groupTaskArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for task in groupTaskArray {
                            self.taskArray += [task]
                        }
                    }
                }
            }
            self.trackGeoRegions()
        }
    }
    
    
    
    
    
    
    
}
