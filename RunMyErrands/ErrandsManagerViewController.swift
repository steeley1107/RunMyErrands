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
    
    var directionTask = DirectionManager()
    var locationManager: GeoManager!
    
    var travelMode = TravelModes.driving
    
    var orderedMarkerArray: [GMSMarker] = []
    var markerArray: [GMSMarker] = []
    
    var errandsManager: ErrandManager!
    
    var activeErrandArray:[Task]!
    
    var direction = Direction()
    
    
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
        
        self.errandsTableView.delegate = self
        self.errandsTableView.dataSource = self
        
        self.direction = Direction()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        errandsManager.fetchIncompleteTask() { (success) -> () in
            if success {
                self.errandsTableView.reloadData()
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
        
        cell.titleLabel.text = nil
        cell.subtitleLabel.text = nil
        cell.titleLabel.attributedText = nil
        cell.subtitleLabel.attributedText = nil
        cell.categoryImage.image = nil
        
        let task:Task = errandsManager.fetchErrand(indexPath)!
        
        cell.titleLabel.text = task.title
        cell.subtitleLabel.text = task.subtitle
        
        let imageName = task.imageName(task.category.intValue)
        cell.categoryImage?.image = UIImage(named:imageName)
        
        
        if task.isActive == false {
            cell.activeLabel.hidden = true
        }
        else if task.isActive == true {
            cell.activeLabel.hidden = false
        }
        
    
        if ContainsTask(activeErrandArray, task: task) && task.isActive == false {
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
            
            let task:Task = errandsManager.fetchErrand(indexPath)!
            
            if cell.accessoryType == .None {
                
                cell.accessoryType = .Checkmark
                if !ContainsTask(activeErrandArray, task: task) {
                    activeErrandArray.append(task)
                }
                
            } else {
                if let index = activeErrandArray.indexOf(task) {
                    cell.accessoryType = .None
                    activeErrandArray.removeAtIndex(index)
                }
            }
            
        }
        errandsTableView.reloadData()
    }
    
    
    //Mark: - Navigation
    
    @IBAction func runErrnadsButton(sender: AnyObject) {
        
        for task in activeErrandArray {
            task.isActive = true
            task.saveInBackground()
        }
        
        performSegueWithIdentifier("ErrandsManagerMap", sender: nil)
    }
    
    
    override func prepareForSegue(segue: (UIStoryboardSegue!), sender: AnyObject!) {
        
        if (segue.identifier == "ErrandsManagerMap") {
            let errandsManagerMapVC:ErrandsManagerMapViewController = segue!.destinationViewController as! ErrandsManagerMapViewController
            direction.markerArray.removeAll()
            
            for activeTask in self.activeErrandArray {
                let marker = activeTask.makeMarker()
                marker.userData = activeTask
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
    
    
    @IBAction func finalDestination(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            direction.destinationHome = false
            break
        case 1:
            direction.destinationHome = true
            break
        default:
            direction.destinationHome = false
            break;
        }
    }
    
    
    @IBAction func FinishErrands(sender: AnyObject) {
        
        direction.markerArray.removeAll()
        
        for task in activeErrandArray {
                task.isActive = false
        }
        
        for task in activeErrandArray {
            task.saveInBackgroundWithBlock{(success: Bool, error: NSError?) ->Void in
                if (success) {
                    if let index = self.activeErrandArray.indexOf(task) {
                        self.activeErrandArray.removeAtIndex(index)
                        
                        self.errandsManager.fetchIncompleteTask() { (success) -> () in
                            if success {
                                self.errandsTableView.reloadData()
                            }
                        }
                    }
                    else
                    {
                        print("problem saving errands")
                    }
                }
            }
        }
    }
    
    func ContainsTask(array: [Task], task: Task) -> Bool {
        
        for activeTask in array {
            
            if task.objectId == activeTask.objectId {
                return true
            }
        }
        return false
    }
    
    
    
    
}
