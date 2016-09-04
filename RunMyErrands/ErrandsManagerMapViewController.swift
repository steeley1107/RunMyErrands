//
//  ErrandsManagerMapViewController.swift
//  RunMyErrands
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
    
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    
    var origin: CLLocationCoordinate2D!
    var destination: CLLocationCoordinate2D!
    
    var directionErrand = DirectionManager()
    var locationManager: GeoManager!
    
    var routePolyline: GMSPolyline!
    
    var legPolyLines:[GMSPolyline] = []
    
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    
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
        
        //Setup Activity Spinner
        activitySpinner.hidesWhenStopped = true
        self.mapView.addSubview(activitySpinner)
        self.mapView.bringSubviewToFront(activitySpinner)
        
        directionsLabel.hidden = true
        
        errandsTableView.tableFooterView = UIView()
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
            
        }
    }
    
    
    func getHomeLocation() {
        
        activitySpinner.startAnimating()
        
        //Check to see if the home address is valid
        directionErrand.HomeAddressValid({ (result) -> Void in
            if result == true {
                let user = PFUser.currentUser()
                if let homeAddress = user!["home"] {
                    let destinationAddress = homeAddress as! String
                    let geocoder = CLGeocoder()
                    
                    geocoder.geocodeAddressString(destinationAddress, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                        if let placemark = placemarks?[0] {
                            let location = placemark.location
                            self.destination = location!.coordinate
                            self.createRoute()
                        }
                    })
                }
                
            }else {
                self.createRoute()
            }
        })
    }
    
    
    //Add the start and destination markers for the route.
    func configureMapAndMarkersForRoute() {
        
        originMarker = GMSMarker(position: self.origin)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = "Start Location"
        let originString = self.directionErrand.originAddress
        if let range = originString.rangeOfString(",") {
            let originAddress = originString[originString.startIndex..<range.startIndex]
            originMarker.snippet = originAddress
        }
        
        if direction.destinationHome == true && destination != nil{
            
            destinationMarker = GMSMarker(position: self.destination)
            destinationMarker.map = self.mapView
            destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
            destinationMarker.title = "Home"
            let destinationString = self.directionErrand.destinationAddress
            if let range = destinationString.rangeOfString(",") {
                let destinationAddress = destinationString[destinationString.startIndex..<range.startIndex]
                destinationMarker.snippet = destinationAddress
            }
        }
    }
    
    //create route on map including zooming window to fit and polylines on screen
    func createRoute() {
        
        if direction.destinationHome == false || destination == nil {
            destination = origin
        }
        
        self.directionErrand.requestDirections(origin, destination: destination, errandWaypoints: direction.markerArray, travelMode: direction.travelMode, completionHandler: { (success) -> Void in
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
                
                self.configureMapAndMarkersForRoute()
            }
            self.activitySpinner.stopAnimating()
        })
    }
    
    
    func drawRoute() {
        let route = directionErrand.overviewPolyline["points"] as! String
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
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
        directionsLabel.text = directionErrand.totalDistance + "\n" + directionErrand.totalTravelDuration + "\n" + directionErrand.totalDuration
    }
    
    
    //Mark: MarkerInfoWindow
    
    func mapView(mapView: GMSMapView!, markerInfoWindow marker: GMSMarker!) -> UIView! {
        let infoWindow = NSBundle.mainBundle().loadNibNamed("CustomInfoWindow", owner: self, options: nil).first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPointMake(0.5, -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippet.text = marker.snippet
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
        
        infoWindow.frame = CGRectMake(x, y, width, height)
        infoWindow.layoutIfNeeded()
        
        //show path //
        
        for polyline in legPolyLines {
            polyline.map = nil
        }
        
        if marker.title == "Home" || (marker.title == "Start Location" && direction.destinationHome == false) {
            
            let legIndex = directionErrand.waypointOrder.count
            let routes = directionErrand.legPolyline(legIndex)
            
            for aRoute in routes {
                aRoute.map = mapView
                legPolyLines += [aRoute]
            }
        }
        
        if let index = orderedMarkerArray.indexOf(marker) {
            let routes = directionErrand.legPolyline(index)
            
            for aRoute in routes {
                aRoute.map = mapView
                legPolyLines += [aRoute]
            }
        }
        
        
        if marker.userData != nil {
            
            let errand:Errand = marker.userData as! Errand
            let imageName:String = errand.imageName(errand.category.intValue)
            infoWindow.icon.image = UIImage(named:imageName)
            
            for eachMarker in orderedMarkerArray {
                eachMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
            }
            marker.icon = GMSMarker.markerImageWithColor(UIColor.cyanColor())
        }
        return infoWindow
    }
    
    
    func zoomMap() {
        
        if let origin = origin {
            let bounds =  self.directionErrand.zoomMapLimits(origin, destination: destination, markerArray: direction.markerArray)
            self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withPadding: 50.0))
            mapView.animateToViewingAngle(45)
        }
    }
    
    
    //Mark: - Navigation
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        
        if marker.userData != nil {
            performSegueWithIdentifier("showDetailFromEMan", sender: marker.userData as! Errand)
        }
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "showDetailFromEMan") {
            let detailVC:DetailViewController = segue!.destinationViewController as! DetailViewController
            detailVC.errand = sender as! Errand
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
        
        let errand:Errand = orderedMarkerArray[indexPath.row].userData as! Errand
        
        cell.titleLabel.text = errand.title
        cell.subtitleLabel.text = errand.subtitle
        
        let imageName = errand.imageName(errand.category.intValue)
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
        
        //Draw polyline on map from errand to errand.
        for polyline in legPolyLines {
            polyline.map = nil
        }
        
        let routes = directionErrand.legPolyline(indexPath.row)
        
        for aRoute in routes {
            aRoute.map = mapView
            legPolyLines += [aRoute]
        }
        
    }
    
    
    //Re-order the waypoints based off google directions.
    func reorderWaypoints() -> [GMSMarker] {
        
        var orderedMarkerArray:[GMSMarker] = [GMSMarker]()
        if let waypointOrder = directionErrand.waypointOrder {
            for indexNumber in waypointOrder {
                orderedMarkerArray += [direction.markerArray[indexNumber]]
            }
        }
        return orderedMarkerArray
    }
    
    
    
}

