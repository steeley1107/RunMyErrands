//
//  ViewController.swift
//  RunMyErrands2Maps
//
//  Created by Steele on 2015-11-30.
//  Copyright © 2015 Steele. All rights reserved.
//

import UIKit
import GoogleMaps





class ErrandsManagerMapViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, GMSMapViewDelegate{
    
    
    //Mark: Properties
    
    @IBOutlet var mapView: GMSMapView!
    
    @IBOutlet weak var directionsLabel: UILabel!
    
    @IBOutlet weak var errandsTableView: UITableView!
    
    var origin: CLLocationCoordinate2D!
    var destination: CLLocationCoordinate2D!
    
    var directionTask = DirectionManager()
    var locationManager: GeoManager!
    
    var routePolyline: GMSPolyline!
    
    var originMarker: GMSMarker!
    
    var didFindMyLocation = false
    
    var orderedMarkerArray: [GMSMarker] = []
    
    var errandsManager: ErrandManager!
    
    var direction = Direction()
    
    
    //Mark: Load ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.errandsManager = ErrandManager()
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        self.errandsTableView.delegate = self
        self.errandsTableView.dataSource = self
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        self.mapView.addSubview(directionsLabel)
        self.mapView.bringSubviewToFront(directionsLabel)
        
        
        directionsLabel.hidden = true
    }
    
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            mapView.animateToViewingAngle(45)
            origin = myLocation.coordinate
            getHomeLocation()
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
            configureMapAndMarkersForRoute()
            
        }
    }
    
    
    func getHomeLocation() {
        
        let user = PFUser.currentUser()
        let tempHome = "128 west hastings st. Vancouver On"
        //if let homeAddress = user!["home"] {
        
        //let destinationAddress = homeAddress as! String
        let  destinationAddress = tempHome
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(destinationAddress, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            if let placemark = placemarks?[0] {
                
                let location = placemark.location
                self.destination = location!.coordinate
            }
        })
    
        //}
    }
    
    
    func configureMapAndMarkersForRoute() {
        //self.mapView.camera = GMSCameraPosition.cameraWithTarget(self.directionTask.originCoordinate, zoom: 14.0)
        
        originMarker = GMSMarker(position: self.origin)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.directionTask.originAddress
        originMarker.snippet = "Start Location"
        
        createRoute()
    }
    
    
    func createRoute() {
        
        if direction.destinationHome == false || destination == nil {
            destination = origin
        }
        
        self.directionTask.requestDirections(origin, destination: destination, taskWaypoints: direction.markerArray, travelMode: direction.travelMode, completionHandler: { (success) -> Void in
            if success {
                self.drawRoute()
                self.displayRouteInfo()
                self.orderedMarkerArray = self.reorderWaypoints()
                self.errandsTableView.reloadData()
                self.zoomMap()
                
                for marker in self.orderedMarkerArray {
                    marker.map = self.mapView
                    marker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                }
                
            }
        })
    }
    
    
    func drawRoute() {
        let route = directionTask.overviewPolyline["points"] as! String
        let path: GMSPath = GMSPath(fromEncodedPath: route)
        routePolyline = GMSPolyline(path: path)
        routePolyline.strokeWidth = 5.0
        routePolyline.map = mapView
    }
    
    
    func clearRoute() {
        originMarker.map = nil
        routePolyline.map = nil
        originMarker = nil
        routePolyline = nil
    }
    
    
    func displayRouteInfo() {
        directionsLabel.hidden = false
        directionsLabel.text = directionTask.totalDistance + "\n" + directionTask.totalTravelDuration + "\n" + directionTask.totalDuration
    }
    
    
    //Mark: MarkerInfoWindow
    
    func mapView(mapView: GMSMapView!, markerInfoWindow marker: GMSMarker!) -> UIView! {
        let infoWindow = NSBundle.mainBundle().loadNibNamed("CustomInfoWindow", owner: self, options: nil).first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPointMake(0.5, -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippit.text = marker.snippet
        
        infoWindow.layoutIfNeeded()
        
        
        
        if marker.userData != nil {
            
            let task:Task = marker.userData as! Task
            let imageName:String = task.imageName(task.category.intValue)
            infoWindow.icon.image = UIImage(named:imageName)
            
            for eachMarker in orderedMarkerArray {
                eachMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
            }
            
            marker.icon = GMSMarker.markerImageWithColor(UIColor.cyanColor())
            
        }
        return infoWindow
    }
    
    
    func zoomMap() {
        
        let bounds =  self.directionTask.zoomMapLimits(origin, markerArray: direction.markerArray)
        self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withPadding: 50.0))
        mapView.animateToViewingAngle(45)
    }
    
    
    
    //Mark: - Navigation
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        performSegueWithIdentifier("showDetailFromEMan", sender: marker.userData as! Task)
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "showDetailFromEMan") {
            let detailVC:DetailViewController = segue!.destinationViewController as! DetailViewController
            detailVC.task = sender as! Task
        }
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderedMarkerArray.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:ErrandsManagerMapTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ErrandsManagerMapTableViewCell
        
        let task:Task = orderedMarkerArray[indexPath.row].userData as! Task
        
        cell.titleLabel.text = task.title
        cell.subtitleLabel.text = task.subtitle
        
        let imageName = task.imageName(task.category.intValue)
        cell.categoryImage?.image = UIImage(named:imageName)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        mapView.selectedMarker = nil
        let marker = orderedMarkerArray[indexPath.row]
        
        for eachMarker in orderedMarkerArray {
            if eachMarker != marker {
                eachMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                
            }
        }
        marker.icon = GMSMarker.markerImageWithColor(UIColor.cyanColor())
        mapView.selectedMarker = marker
    }
    
    //Reorder the waypoints based off google directions.
    func reorderWaypoints() -> [GMSMarker] {
        
        var orderedMarkerArray:[GMSMarker] = [GMSMarker]()
        if let waypointOrder = directionTask.waypointOrder {
            for indexNumber in waypointOrder {
                orderedMarkerArray += [direction.markerArray[indexNumber]]
            }
        }
        return orderedMarkerArray
    }
    
    
    
}

