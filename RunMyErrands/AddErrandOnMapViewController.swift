//
//  AddErrandOnMapViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-06.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import GoogleMaps

class AddErrandOnMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var mapTypeSegment: UISegmentedControl!
    var locationManager: GeoManager!
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var errandArray:[Errand] = []
    var errand: Errand!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //round corners on segment display
        mapTypeSegment.layer.cornerRadius = 5
        mapTypeSegment.layer.masksToBounds = true

        mapView.frame = mapView.bounds
        
        self.locationManager = GeoManager.shared()
        self.locationManager.startLocationManager()
        
        self.mapView.delegate = self
        self.mapView.isMyLocationEnabled = true
        
        self.errandsManager = ErrandManager()
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //Update map with users current location;
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        mapView.clear()
        
        errand.setCoordinate(coordinate)
        errand.geoPoint = PFGeoPoint(latitude:errand.lattitude.doubleValue, longitude:errand.longitude.doubleValue)
        
        
        let marker = GMSMarker(position: coordinate)
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImage(with: UIColor.blue)
    }
    
    @IBAction func mapTypeSelect(_ sender: UISegmentedControl) {
        
        // Available map types: kGMSTypeNormal, kGMSTypeSatellite, kGMSTypeHybrid,
        // kGMSTypeTerrain, kGMSTypeNone
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = kGMSTypeNormal
            break
        case 1:
            mapView.mapType = kGMSTypeSatellite
            break
        case 2:
            mapView.mapType = kGMSTypeHybrid
            break
        default:
            mapView.mapType = kGMSTypeNormal
            break;
        }
    }

    
    
}
