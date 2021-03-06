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
    var directionErrand = DirectionManager()
    var errandsManager: ErrandManager!
    var didFindMyLocation = false
    var ErrandArray:[Errand] = []
    var origin: CLLocationCoordinate2D!
    
    var geoFence = GeoFenceManager()
    
    @IBOutlet weak var mapTypeSegment: UISegmentedControl!
    
    //Mark: ViewController Display
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
    
    override func viewWillAppear(_ animated: Bool) {
        populateErrandArray()
    }
    
    //Update map with users current location;
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
            origin = myLocation.coordinate
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    //Mark: MarkerInfoWindow
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = Bundle.main.loadNibNamed("CustomInfoWindow", owner: self, options: nil)!.first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPoint(x: 0.5, y: -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippet.text = marker.snippet
        
        let errand:Errand = marker.userData as! Errand
        let imageName:String = errand.imageName(Int32(errand.category.intValue))
        infoWindow.icon.image = UIImage(named:imageName)
        
        var textWidth = 0
        
        //auto size the width depending on title size or snippit.
        let x = infoWindow.frame.origin.x
        let y = infoWindow.frame.origin.y
        let height = infoWindow.frame.size.height
        
        let titleWidth = marker.title!.characters.count
        let snippitWidth = marker.snippet!.characters.count
        
        if titleWidth > snippitWidth {
            textWidth = titleWidth
        }else {
            textWidth = snippitWidth
        }
        let width:CGFloat = CGFloat(textWidth) * 7.5 + 70.0
        infoWindow.frame = CGRect(x: x, y: y, width: width, height: height)
        
        infoWindow.layoutIfNeeded()
        
        return infoWindow
    }
    
    
    func addMarkersToMap() {
        
        for Errand in ErrandArray {
            if Errand.isComplete == false {
                
                var marker = GMSMarker()
                marker = Errand.makeMarker()
                marker.userData = Errand
                marker.map = self.mapView
                marker.icon = GMSMarker.markerImage(with: UIColor.red)
            }
        }
    }
    
    
    func zoomMap() {
        
        var markerArray:[GMSMarker] = [GMSMarker]()
        
        for Errand in ErrandArray {
            if Errand.isComplete == false {
                let marker = Errand.makeMarker()
                markerArray.append(marker!)
            }
        }
        if let origin = origin {
            let bounds =  self.directionErrand.zoomMapLimits(origin, destination: origin, markerArray: markerArray)
            self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func populateErrandArray() {
        
        errandsManager.fetchData { (success) -> () in
            if success {
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                
                for index in 0..<numberOfGroups {
                    
                    if let groupErrandArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for Errand in groupErrandArray {
                            self.ErrandArray += [Errand]
                        }
                    }
                }
                self.zoomMap()
                self.addMarkersToMap()
            }
        }
    }
    
    
    //Mark: - Navigation
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        performSegue(withIdentifier: "showDetailFromMap", sender: marker.userData as! Errand)
    }
    
    
    override func prepare(for segue: (UIStoryboardSegue!), sender: Any!) {
        
        if (segue.identifier == "showDetailFromMap") {
            let detailVC:DetailViewController = segue!.destination as! DetailViewController
            detailVC.errand = sender as! Errand
        }
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
