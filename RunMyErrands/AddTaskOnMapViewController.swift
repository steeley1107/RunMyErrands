//
//  AddTaskOnMapViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-06.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import GoogleMaps

class AddTaskOnMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    var locationManager: GeoManager!
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var taskArray:[Task] = []
    var task: Task!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = mapView.bounds
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        
        self.errandsManager = ErrandManager()
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        mapView.clear()
        
        task.setCoordinate(coordinate)
        
        let marker = GMSMarker(position: coordinate)
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
    }
    
    
    
    
}
