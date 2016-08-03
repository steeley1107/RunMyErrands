//
//  AddErrandViewController.swift
//  RunMyErrands
//
//  Created by Steele on 2016-08-02.
//  Copyright © 2016 Jason Steele. All rights reserved.
//

import UIKit
import GooglePlaces


class AddErrandViewController: UIViewController {
    
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
         }
         */
        
}
