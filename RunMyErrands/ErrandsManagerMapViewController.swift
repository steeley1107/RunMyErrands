//
//  ViewController.swift
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


class ErrandsManagerMapViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, GMSMapViewDelegate{
    
    
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var directionsLabel: UILabel!
    
    @IBOutlet weak var errandsTableView: UITableView!
    
    var waypointsArrayString: Array<String> = []
    
    var origin: CLLocationCoordinate2D!
    var destination: CLLocationCoordinate2D!
    
    var directionTask = DirectionManager()
    var locationManager: GeoManager!
    
    var travelMode = TravelModes.driving
    
    var routePolyline: GMSPolyline!
    
    var originMarker: GMSMarker!
    
    var didFindMyLocation = false
    
    var task: Task!
    var taskArray:[Task] = []
    
    var orderedMarkerArray: [GMSMarker] = []
    var markerArray: [GMSMarker] = []
    
    var errandsManager: ErrandManager!
    
    
    //Mark: Load ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = mapView.bounds
        
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
        
        navigationController?.navigationBarHidden = true
        
        directionsLabel.hidden = true
    }
    
    
//    override func viewWillAppear(animated: Bool) {
//        addMarkersToMap()
//    }
    
    
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            //mapView.animateToViewingAngle(45)
            origin = myLocation.coordinate
            didFindMyLocation = true
            //createRoute()
            self.populateTaskArray()
            
        }
    }
    
    
    func configureMapAndMarkersForRoute() {
        //self.mapView.camera = GMSCameraPosition.cameraWithTarget(self.directionTask.originCoordinate, zoom: 14.0)
        
        originMarker = GMSMarker(position: self.directionTask.originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.directionTask.originAddress
        originMarker.snippet = "Location"
        
        if taskArray.count > 0 {
            for task in taskArray {
                
                let marker = task.makeMarker()
                marker.userData = task
                marker.map = mapView
                marker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                markerArray += [marker]
            }
        }
    }
    
    
    func createRoute() {
        
        self.directionTask.requestDirections(origin, taskWaypoints: taskArray, travelMode: self.travelMode, completionHandler: { (success) -> Void in
            if success {
                self.configureMapAndMarkersForRoute()
                self.drawRoute()
                self.displayRouteInfo()
                
                self.orderedMarkerArray = self.reorderWaypoints()
                self.errandsTableView.reloadData()
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
        
        marker.infoWindowAnchor = CGPointMake(4.2, 0.7)
        infoWindow.title.text = marker.title
        infoWindow.snippit.text = marker.snippet
        
        if marker.userData != nil {
            
            let task:Task = marker.userData as! Task
            let imageName:String = task.imageName(task.category.intValue)
            infoWindow.icon.image = UIImage(named:imageName)
            
            for eachMarker in orderedMarkerArray {
                eachMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
            }
            
            marker.icon = GMSMarker.markerImageWithColor(UIColor.cyanColor())
            
        }
        
        //mapView.animateWithCameraUpdate(GMSCameraUpdate.setTarget(marker.position))
        
        
        // camera = GMSCameraPosition.cameraWithTarget(marker.position, zoom: 14.0)
        //mapView.camera = GMSCameraPosition.cameraWithLatitude(marker.position.latitude - 1.11, longitude: marker.position.longitude - 1.1, zoom: 14.0)
        
        
        return infoWindow
    }
    
    
    
    
    
    
    
    //Mark: - Navigation
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        
        performSegueWithIdentifier("GMapDetails", sender: marker.userData as! Task)
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "GMapDetails") {
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
        let cell:ErrandsManagerTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ErrandsManagerTableViewCell
        
        let task:Task = orderedMarkerArray[indexPath.row].userData as! Task
        print("Task \(task)")
        
        cell.titleLabel.text = task.title
        cell.subtitleLabel.text = task.subtitle
        
        let imageName = task.imageName(task.category.intValue)
        cell.categoryImage?.image = UIImage(named:imageName)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let marker = orderedMarkerArray[indexPath.row]
        
        for eachMarker in orderedMarkerArray {
            eachMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        }
        
        marker.icon = GMSMarker.markerImageWithColor(UIColor.cyanColor())
    }
    
    
    func reorderWaypoints() -> [GMSMarker] {
        
        var orderedMarkerArray:[GMSMarker] = [GMSMarker]()
        if let waypointOrder = directionTask.waypointOrder {
            for indexNumber in waypointOrder {
                orderedMarkerArray += [markerArray[indexNumber]]
            }
        }
        return orderedMarkerArray
    }
    
    
    func populateTaskArray() {
        
        errandsManager.fetchDataNew { (sucess) -> () in
            if sucess {
                
                self.taskArray.removeAll()
                
                let numberOfGroups = self.errandsManager.fetchNumberOfGroups()
                for var index in 0..<numberOfGroups {
                    if let groupTaskArray = self.errandsManager.fetchErrandsForGroup(index) {
                        
                        for task in groupTaskArray {
                            if task.isComplete == false {
                                self.taskArray += [task]
                            }
                        }
                    }
                }
                self.createRoute()
            }
        }
    }
    
    
    
    
    
}

