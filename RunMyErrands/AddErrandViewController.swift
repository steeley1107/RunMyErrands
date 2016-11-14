//
//  AddErrandViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2016-08-02.
//  Copyright © 2016 Jason Steele. All rights reserved.
//

import UIKit
import GooglePlaces


class AddErrandViewController: UIViewController, GMSMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
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
        self.mapView.myLocationEnabled = true
        mapView.frame = mapView.bounds
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        errand.category = 0
        
        
        fetchGroupPickerData()
        
        //Add tool bar on top of the picker view
        let toolBar = UIToolbar()
        toolBar.frame = CGRectMake(0,0,self.view.frame.size.width,50)
        toolBar.barStyle = UIBarStyle.Default
        //Create done button
        let barButtonDone = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(AddErrandViewController.dismissPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        //Add button to toolbar
        toolBar.setItems([spaceButton, spaceButton, barButtonDone], animated: false)
        toolBar.userInteractionEnabled = true
        
        //code setup for picker view to popup when text is selected
        categoryPickerView.frame = CGRectMake(0, 50, 100, view.bounds.height * 0.33)
        categoryPickerView.backgroundColor = UIColor(red: 3/255.0, green: 58/255.0, blue: 105/255.0, alpha: 1.0)
        categoryPickerView.dataSource = self
        categoryPickerView.delegate = self
        categoryPickerView.showsSelectionIndicator = true
        categoryPickerView.tag = 1;
        categoryTextField.inputView = self.categoryPickerView;
        categoryTextField.inputAccessoryView = toolBar
        
        groupPickerView.frame = CGRectMake(0, 50, 100, view.bounds.height * 0.33)
        groupPickerView.backgroundColor = UIColor(red: 3/255.0, green: 58/255.0, blue: 105/255.0, alpha:1.0)
        groupPickerView.dataSource = self
        groupPickerView.delegate = self
        groupPickerView.showsSelectionIndicator = true
        groupPickerView.tag = 2;
        groupTextField.inputView = self.groupPickerView;
        groupTextField.inputAccessoryView = toolBar
    }
    
    
    @IBAction func saveButton(sender: AnyObject) {
        
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
            errand.title = errandNameTextField.text?.capitalizedString
            errand.errandDescription = descriptionTextField.text?.capitalizedString
            errand.subtitle = errand.locationName.capitalizedString
            errand.category = categoryPickerView.selectedRowInComponent(0)
            
            errand.isActive = false
            errand.isComplete = false
            
            let groupChoice:NSNumber = groupPickerView.selectedRowInComponent(0)
            let group:PFObject = self.groups[self.groupPickerView.selectedRowInComponent(0)] as! PFObject
            errand.group = group.objectId;
            
            saveErrand()
        }
    }
    
    
    func saveErrand() {
        errand.saveInBackgroundWithBlock { (succeeded, error) in
            if succeeded
            {
                let group:PFObject = self.groups[self.groupPickerView.selectedRowInComponent(0)] as! PFObject
                let groupErrandsRelation:PFRelation = group.relationForKey("Errand")
                groupErrandsRelation.addObject(self.errand)
                
                self.errand.isActive = false
                
                group.saveInBackgroundWithBlock({ (succeeded, error) in
                    if succeeded == false
                    {
                        print("Error \(error)")
                    }
                    else
                    {
                        self.navigationController?.popViewControllerAnimated(true)
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
        
        //Set silent push notification        
        //New Push Notifications with cloud code
        var setChannel = self.errand.group
        PFCloud.callFunctionInBackground("silentPush", withParameters: ["channels": setChannel,"deviceType":"ios"]) { (response, error) -> Void in
        }
        
        
        
    }
    
    //Update map with users current location;
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 14.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
            mapView.removeObserver(self, forKeyPath: "myLocation")
        }
    }
    
    
    @IBAction func searchLocationButton(sender: AnyObject) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        //Create Search Area
        let visibleRegion : GMSVisibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.farRight)
        autocompleteController.autocompleteBounds = bounds
        
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Picker Delegate Function
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
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
    
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        
        let tView = UILabel()
        
        tView.font = UIFont(name: "Helvetica Neue", size:20.0)
        tView.textColor = UIColor.whiteColor()
        
        tView.backgroundColor = UIColor.clearColor() //(red:45/255.0, green:47/255.0, blue:51/255.0, alpha:1.0)
        tView.textAlignment = .Center
        
        
        if pickerView.tag == 1
        {
            self.categoryTextField.text = categoryPickerData[row].capitalizedString
        }
        else if pickerView.tag == 2
        {
            self.groupTextField.text = groupPickerData[row].capitalizedString
        }
        
        // Fill the label text here
        if pickerView.tag == 1
        {
            tView.text = categoryPickerData[row].capitalizedString
        }
        else if pickerView.tag == 2
        {
            tView.text = groupPickerData[row].capitalizedString
        }
        
        return tView;
    }
    
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 1
        {
            categoryTextField.text = categoryPickerData[row].capitalizedString
        }
        else if pickerView.tag == 2
        {
            groupTextField.text = groupPickerData[row].capitalizedString
        }
    }
    
    
    func dismissPicker()
    {
        categoryTextField.resignFirstResponder()
        groupTextField.resignFirstResponder()
    }
    
    
    func fetchGroupPickerData() {
        
        let user = PFUser.currentUser()
        let relation = user!.relationForKey("memberOfTheseGroups")
        
        relation.query().findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if let error = error {
                // There was an error
            } else {
                self.groups = objects!
                for object in objects!
                {
                    self.groupPickerData.addObject(object["name"])
                }
            }
        }
    }
    
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController!,
                           didFailAutocompleteWithError error: NSError!){
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    
    func didUpdateAutocompletePredictionsForResultsController(resultsController: GMSAutocompleteResultsViewController!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    
    func mapView(mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = NSBundle.mainBundle().loadNibNamed("CustomInfoWindow", owner: self, options: nil)!.first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPointMake(0.5, -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippet.text = marker.snippet
        
        let errand:Errand = marker.userData as! Errand
        let imageName:String = errand.imageName(errand.category.intValue)
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
        infoWindow.frame = CGRectMake(x, y, width, height)
        
        infoWindow.layoutIfNeeded()
        
        return infoWindow
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


extension AddErrandViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        print("Place attributions: ", place.attributions)
        self.dismissViewControllerAnimated(true, completion: nil)
        
        //add GMSPlace to Errand
        
        errand.locationName = place.name
        errand.address = place.formattedAddress
        errand.lattitude = place.coordinate.latitude
        errand.longitude = place.coordinate.longitude
        
        //Place holders??
        errand.title = place.name
        
        //Capture just the 1st part of the address
        let formattedAddress = place.formattedAddress?.componentsSeparatedByString(",")
        let simpleAddress: String = formattedAddress![0]
        errand.subtitle = simpleAddress
        
        mapView.clear()
        
        errand.setCoordinate(place.coordinate)
        errand.geoPoint = PFGeoPoint(latitude:errand.lattitude.doubleValue, longitude:errand.longitude.doubleValue)
        
        let marker = errand.makeMarker()
        marker.userData = errand
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        
        marker.map = self.mapView
        
        //Show info window
        mapView.selectedMarker = marker
        
        //Centre the map around the map
        let camera = GMSCameraPosition.cameraWithTarget(errand.coordinate(), zoom: 8)
        mapView.camera = camera
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

