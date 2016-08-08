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
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var errandNameTextField: UITextField!
    @IBOutlet weak var groupTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    var categoryPickerView = UIPickerView()
    var groupPickerView = UIPickerView()
    var categoryPickerData = ["General", "Entertainment", "Business", "Food"]
    var groupPickerData = NSMutableArray()
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    var errand = Errand()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Map View setup
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        mapView.frame = mapView.bounds
        
        //Google Places setup
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        self.navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        fetchGroupPickerData()
        
        //Add tool bar on top of the picker view
        
        var toolBar = UIToolbar()
        toolBar.frame = CGRectMake(0,0,self.view.frame.size.width,50)
        toolBar.barStyle = UIBarStyle.Default
        //Create done button
        let barButtonDone = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "dismissPicker")
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
        groupTextField.inputAccessoryView = toolBar;
        
        
        
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
        
        var user = PFUser.currentUser()
        var relation = user!.relationForKey("memberOfTheseGroups")
        
        relation.query().findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if let error = error {
                // There was an error
            } else {
                for object in objects!
                {
                    self.groupPickerData.addObject(object["name"])
                }
            }
        }
    }
    
}


// Handle the user's selection.
extension AddErrandViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(resultsController: GMSAutocompleteResultsViewController!,
                           didAutocompleteWithPlace place: GMSPlace!) {
        searchController?.active = false
        // Do something with the selected place.
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        print("Place attributions: ", place.attributions)
        
        if let locationName = place?.name
        {
            errand.locationName = locationName
        }
        if let formattedAddress = place?.formattedAddress
        {
            errand.address = formattedAddress
        }
        if let latitude = place?.coordinate.latitude
        {
            errand.lattitude = latitude
        }
        if let longitude = place?.coordinate.longitude
        {
            errand.longitude = longitude
        }
        
        //errand.geoPoint = place.coordinate as PFGeoPoint
        
        mapView.clear()
        
        errand.setCoordinate(place.coordinate)
        errand.geoPoint = PFGeoPoint(latitude:errand.lattitude.doubleValue, longitude:errand.longitude.doubleValue)
        
        let marker = errand.makeMarker()
        marker.userData = errand
        marker.map = self.mapView
        marker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        
        marker.map = self.mapView
        
        //Centre the map around the map
        let camera = GMSCameraPosition.cameraWithTarget(errand.coordinate(), zoom: 8)
        mapView.camera = camera
        
        
        
        
        
        
        
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
    
    
    func mapView(mapView: GMSMapView!, markerInfoWindow marker: GMSMarker!) -> UIView! {
        let infoWindow = NSBundle.mainBundle().loadNibNamed("CustomInfoWindow", owner: self, options: nil).first! as! CustomInfoWindow
        
        marker.infoWindowAnchor = CGPointMake(0.5, -0.0)
        infoWindow.title.text = marker.title
        infoWindow.snippit.text = marker.snippet
        
        let errand:Errand = marker.userData as! Errand
        let imageName:String = errand.imageName(errand.category.intValue)
        infoWindow.icon.image = UIImage(named:imageName)
        
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
        
        return infoWindow
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
