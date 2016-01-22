//
//  ErrandsManagerViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2015-12-08.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit

class ErrandsManagerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //Mark: Properties
    
    @IBOutlet weak var errandsTableView: UITableView!
    @IBOutlet weak var transportationSegment: UISegmentedControl!
    @IBOutlet weak var finalDestinationSegment: UISegmentedControl!
    
    var origin: CLLocationCoordinate2D!
    var destination: CLLocationCoordinate2D!
    
    var directionErrand = DirectionManager()
    var locationManager: GeoManager!
    
    var travelMode = TravelModes.driving
    
    var orderedMarkerArray: [GMSMarker] = []
    var markerArray: [GMSMarker] = []
    
    var errandsManager: ErrandManager!
    
    var activeErrandArray:[Errand]!
    
    var direction = Direction()
    
    var refreshControl:UIRefreshControl!
    
    var scheduler = Scheduler()
    
    
    //Mark:  Load ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //clean up corners on segments
        finalDestinationSegment.layer.cornerRadius = 5
        finalDestinationSegment.layer.masksToBounds = true
        transportationSegment.layer.cornerRadius = 5
        transportationSegment.layer.masksToBounds = true
        
        self.errandsManager = ErrandManager()
        self.activeErrandArray = []
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        self.errandsTableView.tableFooterView = UIView()
        self.errandsTableView.delegate = self
        self.errandsTableView.dataSource = self
        
        self.direction = Direction()
        
        //Update tableView with pulldown
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.errandsTableView.addSubview(refreshControl)

        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        //Remove all completed errrands from active errands array.
        for Errand in self.activeErrandArray {
            if Errand.isComplete  == true {
                
                if let index = self.activeErrandArray.indexOf(Errand) {
                    self.activeErrandArray.removeAtIndex(index)
                }
            }
        }
        
        //Fetch all incomplete errands and reload the table array
        errandsManager.fetchIncompleteErrand() { (success) -> () in
            
            if success {
                self.errandsTableView.reloadData()
            }
        }
        
        
        //Check if any errands have expired.
        self.scheduler.CheckActiveErrandsExpiry()
        self.scheduler.CheckCompletedErrandsExpiry()
        
    }
    
    
    //reload errands table from pulling down on errands
    func refresh(sender:AnyObject) {
        
        for Errand in self.activeErrandArray {
            if Errand.isComplete  == true {
                
                if let index = self.activeErrandArray.indexOf(Errand) {
                    self.activeErrandArray.removeAtIndex(index)
                }
            }
        }
        
        errandsManager.fetchIncompleteErrand() { (success) -> () in
            
            if success {
                self.errandsTableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let count:Int = self.errandsManager.fetchNumberOfGroups() as Int
        return count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count:Int = self.errandsManager.fetchNumberOfRowsInSection(section)
        return count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:ErrandsManagerTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ErrandsManagerTableViewCell
        
        //reset each cell in table.
        cell.selectionStyle = .None
        
        cell.titleLabel.text = nil
        cell.subtitleLabel.text = nil
        cell.titleLabel.attributedText = nil
        cell.subtitleLabel.attributedText = nil
        cell.categoryImage.image = nil
        
        let errand:Errand = errandsManager.fetchErrand(indexPath)!
        
        cell.titleLabel.text = errand.title
        cell.subtitleLabel.text = errand.subtitle
        
        let imageName = errand.imageName(errand.category.intValue)
        cell.categoryImage?.image = UIImage(named:imageName)
        
        
        if errand.isActive == false {
            cell.activeLabel.hidden = true
        }
        else if errand.isActive == true {
            cell.activeLabel.hidden = false
        }
        
        
        if ContainsErrand(activeErrandArray, errand: errand) && errand.isActive == false {
            cell.accessoryType = .Checkmark
        }else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.errandsManager.fetchTitleForHeaderInSection(section)
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //After tapping highlight doesn't linger
        errandsTableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            
            let errand:Errand = errandsManager.fetchErrand(indexPath)!
            
            if cell.accessoryType == .None {
                
                cell.accessoryType = .Checkmark
                if !ContainsErrand(activeErrandArray, errand: errand) {
                    activeErrandArray.append(errand)
                }
                
            } else {
                if let index = activeErrandArray.indexOf(errand) {
                    cell.accessoryType = .None
                    activeErrandArray.removeAtIndex(index)
                }
            }
            
        }
        errandsTableView.reloadData()
    }
    
    
    //Mark: - Navigation
    
    @IBAction func runErrnadsButton(sender: AnyObject) {
        
        //check to see if any errands have been selected
        if activeErrandArray.count == 0 {
            showAlert("Error", message: "Please Select Errands to Run")
        }
        
        for Errand in activeErrandArray {
            Errand.isActive = true
            Errand.activeDate = Errand.setActiveErrandExpiryDate()
            Errand.saveInBackground()
        }
        
        performSegueWithIdentifier("ErrandsManagerMap", sender: nil)
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "ErrandsManagerMap") {
            let errandsManagerMapVC:ErrandsManagerMapViewController = segue!.destinationViewController as! ErrandsManagerMapViewController
            direction.markerArray.removeAll()
            
            for activeErrand in self.activeErrandArray {
                let marker = activeErrand.makeMarker()
                marker.userData = activeErrand
                direction.markerArray += [marker]
            }
            
            errandsManagerMapVC.direction = direction
        }
    }
    
    
    //Mark: Mode selections
    @IBAction func travelMode(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            direction.travelMode = .driving
            break
        case 1:
            direction.travelMode = .walking
            break
        case 2:
            direction.travelMode = .bicycling
            break
        default:
            direction.travelMode = .driving
            break;
        }
    }
    
    
    //Select if the errands will be round trip or if the destination will be the users home.
    @IBAction func finalDestination(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            direction.destinationHome = false
            break
        case 1:
            direction.destinationHome = true
            
            //Check to see if the home address is valid
            directionErrand.HomeAddressValid({ (result) -> Void in
                if result == false {
                    self.showAlert("Home Address Not Valid", message: "Please Set Home Address in Settings")
                }
            })
            break
        default:
            direction.destinationHome = false
            break;
        }
    }
    
    
    //Done running errands.  Stop errands from being active.
    @IBAction func FinishErrands(sender: AnyObject) {
        
        //Remove all errands from Map.
        direction.markerArray.removeAll()
        
        //Change all errands to not active.
        for Errand in activeErrandArray {
            Errand.isActive = false
        }
        
        //Save all recenlty active errands in the background
        for Errand in activeErrandArray {
            Errand.saveInBackgroundWithBlock{(success: Bool, error: NSError?) ->Void in
                if (success) {
                    if let index = self.activeErrandArray.indexOf(Errand) {
                        self.activeErrandArray.removeAtIndex(index)
                    }
                    else {
                        print("problem saving errands \(error)")
                    }
                }
            }
        }
        //Update table after all the active Erranded are reset.
        self.errandsManager.fetchIncompleteErrand() { (success) -> () in
            if success {
                self.errandsTableView.reloadData()
            }
        }
    }
    
    
    //Check for active Errands in an array of Errands.
    func ContainsErrand(array: [Errand], errand: Errand) -> Bool {
        
        for activeErrand in array {
            
            if errand.objectId == activeErrand.objectId {
                return true
            }
        }
        return false
    }
    
    
    //Alert Controller for the errand manager
    func showAlert(title: String, message: String) {
        
        // create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        // show the alert
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    
}
