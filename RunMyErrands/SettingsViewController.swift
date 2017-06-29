//
//  SettingsViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-10.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit



class SettingsViewController: UIViewController {

    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var pictureImageView: UIImageView!
    
    @IBOutlet weak var notifySwitch: UISwitch!
    
    @IBOutlet weak var geoFenceSegment: UISegmentedControl!
    
    @IBOutlet weak var geoFenceCount: UILabel!
    var user: PFUser?
    
    var locationManager: GeoManager!
    
    let kDrivingGeoRadius = 500
    let kBicyclingGeoRadius = 200
    let kWalkingGeoRadius = 100
    
    var geoRadius = 200;

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //round corners on segment display
        geoFenceSegment.layer.cornerRadius = 5
        geoFenceSegment.layer.masksToBounds = true
        
        self.locationManager = GeoManager.shared()
        self.locationManager.startLocationManager()
        self.notifySwitch.accessibilityLabel = "Receive Notification";
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        user!["pushNotify"] = notifySwitch.isOn
        user!["geoRadius"] = geoRadius
        user?.saveInBackground()
        
        let pushNotify = (user!["pushNotify"] as AnyObject).boolValue
        
        if (pushNotify != nil) {

            let currentInstallation = PFInstallation.current()
            let errandManager = ErrandManager()
            errandManager.fetchData({ (success) -> () in
                var channels:[String]
                channels = errandManager.fetchKeys()
                currentInstallation.channels = channels
                currentInstallation.saveInBackground()
            })
            
        } else {
            let currentInstallation = PFInstallation.current()
            currentInstallation.channels = []
            currentInstallation.saveInBackground()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        user = PFUser.current()

        userLabel.text = (user!["name"] as AnyObject).capitalized
        
        if let status = user!["status"] as? String {
            if status == "" {
                statusLabel.text = "N/A"
            }else {
                statusLabel.text = status
            }
        } else {
            statusLabel.text = "N/A"
        }
        
        if let home = user!["home"] as? String {
            if home == "" {
                addressLabel.text = "N/A"
            }else {
                addressLabel.text = home
            }
        } else {
            addressLabel.text = "N/A"
        }
        
        notifySwitch.isOn = (user!["pushNotify"] as AnyObject).boolValue
        
        geoRadius = (user!["geoRadius"] as? Int)!
        if geoRadius == kWalkingGeoRadius {
            geoFenceSegment.selectedSegmentIndex = 1
        }else if geoRadius == kBicyclingGeoRadius {
            geoFenceSegment.selectedSegmentIndex = 2
        }else {
            geoFenceSegment.selectedSegmentIndex = 0
        }
        
        
        let image = user!["profile_Picture"] as? PFFile

        if (image == nil) {
            self.pictureImageView.image = UIImage(named: "runmyerrands-grey")
        } else {
            image!.getDataInBackground(block: { (data: Data?, error: NSError?) -> Void in
                self.pictureImageView.layer.masksToBounds = true
                self.pictureImageView.layer.cornerRadius = self.pictureImageView.frame.size.height/2
                DispatchQueue.main.async(execute: { () -> Void in
                    if error == nil {
                        self.pictureImageView.image = UIImage(data: data!)
                    } else {
                        print("Error: \(error)")
                    }
                })
            } as! PFDataResultBlock)
        }
        //display the number of regions are being monitored
        geoFenceCount.text = "\(locationManager.monitoredRegions())"
    }

    @IBAction func geoFenceDistance(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            geoRadius = kDrivingGeoRadius
            break
        case 1:
            geoRadius = kWalkingGeoRadius
            break
        case 2:
            geoRadius = kBicyclingGeoRadius
            break
        default:
            geoRadius = kDrivingGeoRadius
            break;
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

