
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
    
    
    @IBAction func homeLookup(_ sender: AnyObject) {
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
    
    
    @IBAction func editProfile(_ sender: UIButton) {
        user!["name"] = nameTextField.text
        user!["status"] = statusTextField.text
        user!["home"] = addressTextField.text
        
        user?.saveInBackground()
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
}

extension EditProfileViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        addressTextField.text = place.formattedAddress
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}


