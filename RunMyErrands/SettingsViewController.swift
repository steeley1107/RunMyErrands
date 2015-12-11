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
    
    @IBOutlet weak var radiusLabel: UILabel!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var notifySwitch: UISwitch!
    
    var user: PFUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        user!["pushNotify"] = notifySwitch.on
        user!["geoRadius"] = NSNumber(float: slider.value)
        user?.saveInBackground()
        
        let pushNotify = user!["pushNotify"].boolValue
        
        if (pushNotify != nil) {

            let currentInstallation = PFInstallation.currentInstallation()
            let errandManager = ErrandManager()
            errandManager.fetchData({ (success) -> () in
                var channels:[String]
                channels = errandManager.fetchKeys()
                currentInstallation.channels = channels
                currentInstallation.saveInBackground()
            })
            
        } else {
            let currentInstallation = PFInstallation.currentInstallation()
            currentInstallation.channels = []
            currentInstallation.saveInBackground()
        }
    }
    
    func sliderValueChanged(sender: AnyObject) {
        let slider = sender as! UISlider
        radiusLabel.text = "\(Int(slider.value))"
    }
    
    override func viewWillAppear(animated: Bool) {
        
        user = PFUser.currentUser()

        userLabel.text = user!["name"].capitalizedString
        
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
        
        notifySwitch.on = user!["pushNotify"].boolValue
        
        slider.maximumValue = 1000
        slider.minimumValue = 100
        let initSliderValue = user!["geoRadius"] as? NSNumber
        slider.value = (initSliderValue?.floatValue)!
        radiusLabel.text = "\(Int(slider.value))"
        
        slider.addTarget(self, action: "sliderValueChanged:", forControlEvents: .ValueChanged)
        
        let image = user!["profile_Picture"] as? PFFile

        if (image == nil) {
            self.pictureImageView.image = UIImage(named: "runmyerrands-grey")
        } else {
            image!.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                self.pictureImageView.layer.masksToBounds = true
                self.pictureImageView.layer.cornerRadius = self.pictureImageView.frame.size.height/2
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if error == nil {
                        self.pictureImageView.image = UIImage(data: data!)
                    } else {
                        print("Error: \(error)")
                    }
                })
            })
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