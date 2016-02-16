//
//  EditErrandOnMapViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2016-02-15.
//  Copyright © 2016 Jason Steele. All rights reserved.
//

import UIKit
import GoogleMaps

class EditErrandOnMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate
{
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var mapTypeSegment: UISegmentedControl!
    var locationManager: GeoManager!
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var errand: Errand!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //round corners on segment display
        mapTypeSegment.layer.cornerRadius = 5
        mapTypeSegment.layer.masksToBounds = true
        
        //zoom map to the bounds of the errand
        mapView.frame = mapView.bounds
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        
        self.errandsManager = ErrandManager()
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        addMarkersToMap()
    }
    
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if !didFindMyLocation {
            //let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(errand.coordinate(), zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D)
    {
        mapView.clear()
        
        errand.setCoordinate(coordinate)
        errand.geoPoint = PFGeoPoint(latitude:errand.lattitude.doubleValue, longitude:errand.longitude.doubleValue)
        
        
        let marker = GMSMarker(position: coordinate)
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
    }
    
    
    @IBAction func mapTypeSelect(sender: UISegmentedControl)
    {
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
    
    
    func addMarkersToMap()
    {
        let marker = errand.makeMarker()
        marker.userData = errand
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
    }
    
    
}