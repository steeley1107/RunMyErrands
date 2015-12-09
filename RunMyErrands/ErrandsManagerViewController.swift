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
    
    
    var origin: CLLocationCoordinate2D!
    var destination: CLLocationCoordinate2D!
    
    var directionTask = DirectionManager()
    var locationManager: GeoManager!
    
    var travelMode = TravelModes.driving
    
    var task: Task!
    var taskArray:[Task] = []
    
    var orderedMarkerArray: [GMSMarker] = []
    var markerArray: [GMSMarker] = []
    
    var errandsManager: ErrandManager!
    
    
    
    //Mark:  Load ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.errandsManager = ErrandManager()
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()
        
        
        self.errandsTableView.delegate = self
        self.errandsTableView.dataSource = self
        
        
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
        print("count \(count)")
        return count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count:Int = self.errandsManager.fetchNumberOfRowsInSection(section)
        print("count \(count)")
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
            cell.accessoryType = .None
        }
        else if task.isActive == true {
            cell.accessoryType = .Checkmark
        }
        
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.errandsManager.fetchTitleForHeaderInSection(section)
    }
    
    
    
    
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //After tapping highlight doesn't linger
        errandsTableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        let activeErrandsArray = NSMutableArray()
        
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            
            let task:Task = errandsManager.fetchErrand(indexPath)!
            
            if task.isActive == false {
                task.isActive = true
                cell.accessoryType = .Checkmark
                activeErrandsArray.addObject(task)
                
            }else {
                task.isActive = false
                cell.accessoryType = .None
                activeErrandsArray.removeObject(task)
            }
            
            
        }
        
    }
        
        
        
        
        
}
