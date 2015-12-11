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
    var directionTask = DirectionManager()
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var taskArray:[Task] = []
    var origin: CLLocationCoordinate2D!
    
    
    //Mark: ViewController Display
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
    
    override func viewWillAppear(animated: Bool) {
        populateTaskArray()
    }
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            origin = myLocation.coordinate
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
             mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    //Mark: MarkerInfoWindow
    
    func mapView(mapView: GMSMapView!, markerInfoWindow marker: GMSMarker!) -> UIView! {
        let infoWindow = NSBundle.mainBundle().loadNibNamed("CustomInfoWindow", owner: self, options: nil).first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPointMake(0.5, -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippit.text = marker.snippet
        
        let task:Task = marker.userData as! Task
        let imageName:String = task.imageName(task.category.intValue)
        infoWindow.icon.image = UIImage(named:imageName)
        
        infoWindow.layoutIfNeeded()
        
        
        
        return infoWindow
    }

    
    func addMarkersToMap() {
        
        errandsManager.fetchData { (success) -> () in
            if success {
                
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
    
    func zoomMap() {
        
        var markerArray:[GMSMarker] = [GMSMarker]()
        
        for task in taskArray {
            if task.isComplete == false {
                let marker = task.makeMarker()
                markerArray += [marker]
            }
        }
        
        
        let bounds =  self.directionTask.zoomMapLimits(origin, destination: origin, markerArray: markerArray)
        self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withPadding: 50.0))
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
        
        errandsManager.fetchData { (success) -> () in
            if success {
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for var index in 0..<numberOfGroups {
                    
                    if let groupTaskArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for task in groupTaskArray {
                            self.taskArray += [task]
                        }
                    }
                }
            }
            self.zoomMap()
            self.trackGeoRegions()
            self.addMarkersToMap()
        }
    }
    
    
    
    //Mark: - Navigation
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        
        performSegueWithIdentifier("showDetailFromMap", sender: marker.userData as! Task)
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "showDetailFromMap") {
            let detailVC:DetailViewController = segue!.destinationViewController as! DetailViewController
            detailVC.task = sender as! Task
        }
    }
    
    
    
    
    
    
}
