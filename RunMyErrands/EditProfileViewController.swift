
//
//  EditProfileViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-12-10.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

import UIKit
import GooglePlaces

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var statusTextField: UITextField!
    
    @IBOutlet weak var addressTextField: UITextField!
    
    
    
    var user: PFUser?
    var didFindMyLocation = false
    var locationManager: GeoManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = GeoManager.sharedManager()
        self.locationManager.startLocationManager()

        
        // Do any additional setup after loading the view.
        user = PFUser.currentUser()
        nameTextField.text = user!["name"] as? String
        statusTextField.text = user!["status"] as? String
        addressTextField.text = user!["home"] as? String
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func homeLookup(sender: AnyObject) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        let myLocation = locationManager.getCurrentLocation()
        
        if let myLocation = myLocation {
            let nearLeft = CLLocationCoordinate2DMake(myLocation.coordinate.latitude - 0.1, myLocation.coordinate.longitude - 0.1)
            let farRight = CLLocationCoordinate2DMake(myLocation.coordinate.latitude + 0.1, myLocation.coordinate.longitude + 0.1)
            
            let bounds = GMSCoordinateBounds(coordinate: nearLeft, coordinate: farRight)
            autocompleteController.autocompleteBounds = bounds
        }
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func editProfile(sender: UIButton) {
        user!["name"] = nameTextField.text
        user!["status"] = statusTextField.text
        user!["home"] = addressTextField.text
        
        user?.saveInBackground()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
}

extension EditProfileViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        addressTextField.text = place.formattedAddress
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    
    // User canceled the operation.
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    
    func didUpdateAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
}


