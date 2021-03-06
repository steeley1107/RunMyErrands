//
//  EditErrandViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2016-08-27.
//  Copyright © 2016 Jason Steele. All rights reserved.
//

import UIKit
import GooglePlaces


class EditErrandViewController: UIViewController, GMSMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    //Mark: Properties
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var errandNameTextField: UITextField!
    @IBOutlet weak var groupTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    var didFindMyLocation = false
    var categoryPickerView = UIPickerView()
    var groupPickerView = UIPickerView()
    var categoryPickerData = ["General", "Entertainment", "Business", "Food"]
    var groupPickerData = NSMutableArray()
    var errand = Errand()
    var groups = NSArray()
    
    
    //Mark: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Map View setup
        self.mapView.delegate = self
        mapView.frame = mapView.bounds
        
        //Fill in errand data
        populateEdit()
        
        fetchGroupPickerData()
        
        //Add tool bar on top of the picker view
        let toolBar = UIToolbar()
        toolBar.frame = CGRect(x: 0,y: 0,width: self.view.frame.size.width,height: 50)
        toolBar.barStyle = UIBarStyle.default
        //Create done button
        let barButtonDone = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AddErrandViewController.dismissPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        //Add button to toolbar
        toolBar.setItems([spaceButton, spaceButton, barButtonDone], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        //code setup for picker view to popup when text is selected
        categoryPickerView.frame = CGRect(x: 0, y: 50, width: 100, height: view.bounds.height * 0.33)
        categoryPickerView.backgroundColor = UIColor(red: 3/255.0, green: 58/255.0, blue: 105/255.0, alpha: 1.0)
        categoryPickerView.dataSource = self
        categoryPickerView.delegate = self
        categoryPickerView.showsSelectionIndicator = true
        categoryPickerView.tag = 1;
        categoryTextField.inputView = self.categoryPickerView;
        categoryTextField.inputAccessoryView = toolBar
        
        groupPickerView.frame = CGRect(x: 0, y: 50, width: 100, height: view.bounds.height * 0.33)
        groupPickerView.backgroundColor = UIColor(red: 3/255.0, green: 58/255.0, blue: 105/255.0, alpha:1.0)
        groupPickerView.dataSource = self
        groupPickerView.delegate = self
        groupPickerView.showsSelectionIndicator = true
        groupPickerView.tag = 2;
        groupTextField.inputView = self.groupPickerView;
        groupTextField.inputAccessoryView = toolBar
    }
    
    func populateEdit()
    {
        //Load Errand information
        errandNameTextField.text = errand.title
        categoryTextField.text = categoryPickerData[errand.category.intValue]
        descriptionTextField.text = errand.errandDescription

        //Capture just the 1st part of the address
        let formattedAddress = errand.address.components(separatedBy: ",")
        let simpleAddress: String = formattedAddress[0]
        errand.subtitle = simpleAddress
        
        //Load map with errand
        var marker = GMSMarker()
        marker = errand.makeMarker()
        marker.userData = errand
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImage(with: UIColor.red)
        marker.map = self.mapView
        
        //Show info window
        mapView.selectedMarker = marker
        //Centre the map around the map
        let camera = GMSCameraPosition.camera(withTarget: errand.coordinate(), zoom: 14)
        mapView.camera = camera
    }
    
    
    @IBAction func saveButton(_ sender: AnyObject) {
        
        var alertControllerTitle = ""
        var alertControllerMessage = ""
        
        if self.errandNameTextField == nil
        {
            alertControllerTitle = "Enter a Name"
            alertControllerMessage = "Please Enter a Errand Name"
            showAlert(alertControllerTitle, message: alertControllerMessage)
        }
        else if errand.longitude == nil {
            alertControllerTitle = "Enter an Address"
            alertControllerMessage = "Please Select an Destination From The Search"
            showAlert(alertControllerTitle, message: alertControllerMessage)
        }
        else
        {
            errand.title = errandNameTextField.text?.capitalized
            errand.errandDescription = descriptionTextField.text?.capitalized
            errand.subtitle = errand.locationName.capitalized
            errand.category = categoryPickerView.selectedRow(inComponent: 0) as NSNumber
            
            errand.isActive = false
            errand.isComplete = false
            
            //let groupChoice:NSNumber = NSNumber(value: groupPickerView.selectedRow(inComponent: 0))
            let group:PFObject = self.groups[self.groupPickerView.selectedRow(inComponent: 0)] as! PFObject
            errand.group = group.objectId;
            
            saveErrand()
        }
    }
    
    
    func saveErrand() {
        errand.saveInBackground { (succeeded, error) in
            if succeeded
            {
                let group:PFObject = self.groups[self.groupPickerView.selectedRow(inComponent: 0)] as! PFObject
                let groupErrandsRelation:PFRelation = group.relation(forKey: "Errand")
                groupErrandsRelation.add(self.errand)
                
                self.errand.isActive = false
                
                group.saveInBackground(block: { (succeeded, error) in
                    if succeeded == false
                    {
                        print("Error \(String(describing: error))")
                    }
                    else
                    {
                        self.navigationController?.popViewController(animated: true)
                    }
                })
            }
            else
            {
                
                //
                //            // There was a problem, check error.description
                //            NSString *alertControllerTitle = @"Error";
                //            NSString *alertControllerMessage = @"Oops There Was a Problem in Adding The Errand";
                //            [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
            }
        }
    }
    
    
    //Update map with users current location;
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    
    @IBAction func searchLocationButton(_ sender: AnyObject) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        //Create Search Area
        let visibleRegion : GMSVisibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.farRight)
        autocompleteController.autocompleteBounds = bounds
        
        self.present(autocompleteController, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Picker Delegate Function
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1
        {
            return categoryPickerData.count
        }
        else if pickerView.tag == 2
        {
            return self.groupPickerData.count
        }
        else
        {
            return 0
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let tView = UILabel()
        
        tView.font = UIFont(name: "Helvetica Neue", size:20.0)
        tView.textColor = UIColor.white
        
        tView.backgroundColor = UIColor.clear //(red:45/255.0, green:47/255.0, blue:51/255.0, alpha:1.0)
        tView.textAlignment = .center
        
        
        if pickerView.tag == 1
        {
            self.categoryTextField.text = categoryPickerData[row].capitalized
        }
        else if pickerView.tag == 2
        {
            self.groupTextField.text = (groupPickerData[row] as AnyObject).capitalized
        }
        
        // Fill the label text here
        if pickerView.tag == 1
        {
            tView.text = categoryPickerData[row].capitalized
        }
        else if pickerView.tag == 2
        {
            tView.text = (groupPickerData[row] as AnyObject).capitalized
        }
        
        return tView;
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 1
        {
            categoryTextField.text = categoryPickerData[row].capitalized
        }
        else if pickerView.tag == 2
        {
            groupTextField.text = (groupPickerData[row] as AnyObject).capitalized
        }
    }
    
    
    func dismissPicker()
    {
        categoryTextField.resignFirstResponder()
        groupTextField.resignFirstResponder()
    }
    
    
    func fetchGroupPickerData() {
        
        let user = PFUser.current()
        let relation = user!.relation(forKey: "memberOfTheseGroups")
        
        relation.query().findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error != nil {
                // There was an error
            } else {
                self.groups = objects! as NSArray
                for object in objects!
                {
                    self.groupPickerData.add(object["name"])
                    if self.errand.group == object.objectId
                    {
                        self.groupTextField.text = object["name"] as? String
                    }
                }
            }
        }
    }
    
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController!,
                           didFailAutocompleteWithError error: NSError!){
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictionsForResultsController(_ resultsController: GMSAutocompleteResultsViewController!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    
    func didUpdateAutocompletePredictionsForResultsController(_ resultsController: GMSAutocompleteResultsViewController!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = Bundle.main.loadNibNamed("CustomInfoWindow", owner: self, options: nil)!.first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPoint(x: 0.5, y: -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippet.text = marker.snippet
        
        let errand:Errand = marker.userData as! Errand
        let imageName:String = errand.imageName(Int32(errand.category.intValue))
        infoWindow.icon.image = UIImage(named:imageName)
        
        var textWidth = 0
        
        //auto size the width depending on title size or snippit.
        let x = infoWindow.frame.origin.x
        let y = infoWindow.frame.origin.y
        let height = infoWindow.frame.size.height
        
        let titleWidth = infoWindow.title.text!.characters.count
        let snippetWidth = infoWindow.snippet.text!.characters.count
        
        if titleWidth > snippetWidth {
            textWidth = titleWidth
        }else {
            textWidth = snippetWidth
        }
        let width:CGFloat = CGFloat(textWidth) * 7.5 + 70.0
        infoWindow.frame = CGRect(x: x, y: y, width: width, height: height)
        
        infoWindow.layoutIfNeeded()
        
        return infoWindow
    }
    
    
    //Alert Controller for the errand manager
    func showAlert(_ title: String, message: String) {
        
        // create the alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
}


extension EditErrandViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress!)
        print("Place attributions: ", place.attributions!)
        self.dismiss(animated: true, completion: nil)
        
        //add GMSPlace to Errand
        
        errand.locationName = place.name
        errand.address = place.formattedAddress
        errand.lattitude = place.coordinate.latitude as NSNumber
        errand.longitude = place.coordinate.longitude as NSNumber
        
        //Place holders??
        errand.title = place.name
        
        //Capture just the 1st part of the address
        let formattedAddress = place.formattedAddress?.components(separatedBy: ",")
        let simpleAddress: String = formattedAddress![0]
        errand.subtitle = simpleAddress
        
        mapView.clear()
        
        errand.setCoordinate(place.coordinate)
        errand.geoPoint = PFGeoPoint(latitude:errand.lattitude.doubleValue, longitude:errand.longitude.doubleValue)
        
        var marker = GMSMarker();
        marker = errand.makeMarker()
        marker.userData = errand
        marker.map = mapView
        marker.icon = GMSMarker.markerImage(with: UIColor.red)
        
        marker.map = mapView
        
        //Show info window
        mapView.selectedMarker = marker
        
        //Centre the map around the map
        let camera = GMSCameraPosition.camera(withTarget: errand.coordinate(), zoom: 8)
        mapView.camera = camera
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
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

