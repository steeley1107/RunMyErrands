//
//  EditErrandViewController.m
//  RunMyErrands
//
//  Created by Steele on 2016-02-15.
//  Copyright © 2016 Jason Steele. All rights reserved.
//


#import "EditErrandViewController.h"
#import <Parse/Parse.h>
#import "RunMyErrands-Swift.h"

@interface EditErrandViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *errandNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationName;
@property (nonatomic) NSArray *groups;
@property (nonatomic) NSArray *categoryPickerData;
@property (nonatomic) NSMutableArray *groupPickerData;
@property (nonatomic) NSString *teamKey;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UITextField *groupTextField;
@property (strong, nonatomic) UIPickerView *categoryPickerView;
@property (strong, nonatomic) UIPickerView *groupPickerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) UITextField *activeField;
@end

@implementation EditErrandViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.categoryPickerData = @[@"General",@"Entertainment",@"Business",@"Food"];
    self.groupPickerData = [NSMutableArray new];
    [self fetchGroupPickerData];
    
    //Add tool bar on top of the picker view
    UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,30)];
    [toolBar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                      style:UIBarButtonItemStylePlain target:self action:@selector(dismissPicker)];
    toolBar.items = @[barButtonDone];
    barButtonDone.tintColor=[UIColor blueColor];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:flexibleSpace, barButtonDone, nil]];
    
    //code setup for picker view to popup when text is selected
    self.categoryPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
    [self.categoryPickerView setBackgroundColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:51/255.0f alpha:1.0f]];
    [self.categoryPickerView setDataSource: self];
    [self.categoryPickerView setDelegate: self];
    self.categoryPickerView.showsSelectionIndicator = YES;
    self.categoryPickerView.tag = 1;
    self.categoryTextField.inputView = self.categoryPickerView;
    self.categoryTextField.inputAccessoryView = toolBar;
    
    self.groupPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
    [self.groupPickerView setBackgroundColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:51/255.0f alpha:1.0f]];
    [self.groupPickerView setDataSource: self];
    [self.groupPickerView setDelegate: self];
    self.groupPickerView.showsSelectionIndicator = YES;
    self.groupPickerView.tag = 2;
    self.groupTextField.inputView = self.groupPickerView;
    self.groupTextField.inputAccessoryView = toolBar;
    
    //determine the status of the keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}


-(void)dismissPicker
{
    
    [self.categoryTextField resignFirstResponder];
    [self.groupTextField resignFirstResponder];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
}


-(void)fetchGroupPickerData
{
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        
        PFRelation *relation  = [currentUser relationForKey:@"memberOfTheseGroups"];
        [[relation query] findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (!error) {
                self.groups = objects;
                
                for (PFObject *object in objects) {
                    [self.groupPickerData addObject: object[@"name"]];
                }
                [self.groupPickerView reloadAllComponents];
                self.errandNameTextField.text = self.errand.title;
                self.descriptionTextField.text = self.errand.errandDescription;
                self.locationName.text = self.errand.subtitle;
                self.categoryTextField.text = self.categoryPickerData[[self.errand.category intValue]];
                self.groupTextField.text =  self.groupPickerData[[self.errand.group intValue]];
                self.addressTextField.text = self.errand.address;
                
            }
        }];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)saveButtonPressed:(UIButton *)sender
{
    __block NSString *alertControllerTitle;
    __block NSString *alertControllerMessage;
    
    if (self.errandNameTextField.text.length == 0) {
        alertControllerTitle = @"Enter a Name";
        alertControllerMessage = @"Please Enter a errand Name";
        [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
    } else if (self.addressTextField.text.length == 0 && !self.errand.longitude) {
        alertControllerTitle = @"Enter an Address";
        alertControllerMessage = @"Please Enter an Address or Choose it on the Map";
        [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
    } else {
        self.errand.title = [self.errandNameTextField.text capitalizedString];
        self.errand.errandDescription = [self.descriptionTextField.text capitalizedString];
        self.errand.subtitle = [self.locationName.text capitalizedString];
        self.errand.category = @([self.categoryPickerView selectedRowInComponent:0]);
        
        self.errand.isActive = @NO;
        
        NSNumber *groupChoice = @([self.groupPickerView selectedRowInComponent:0]);
        PFObject *group = self.groups[[groupChoice intValue]];
        self.errand.group = group.objectId;
        
        if (self.addressTextField.text.length != 0) {
            self.errand.address = self.addressTextField.text;
            [self geoCodeAddress:self.errand.address];
        }else if (self.errand.coordinate.latitude) {
            self.errand.address = @"";
            [self saveErrand];
        }
    }
}


-(void)saveErrand
{
    [self.errand saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
            PFObject *group = self.groups[[self.groupPickerView selectedRowInComponent:0]];
            PFRelation *groupErrandsRelation = [group relationForKey:@"Errand"];
            
            [groupErrandsRelation addObject:self.errand];
            [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (!succeeded) {
                    NSLog(@"Error: %@", error);
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
            
        } else {
            // There was a problem, check error.description
            NSString *alertControllerTitle = @"Error";
            NSString *alertControllerMessage = @"Oops There Was a Problem in Adding The Errand";
            [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
        }
    }];
}


-(void) presentAlertController:(NSString *)title aMessage:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   //
                                               }];
    
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma - UITapGestureRecognizer Delegate Functions

- (IBAction)tapDetected:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
}

#pragma - UIPickerView Delegate Functions

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView.tag == 1) {
        return self.categoryPickerData.count;
    } else if (pickerView.tag == 2) {
        return self.groupPickerData.count;
    } else {
        return 0;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* tView = (UILabel*)view;
    if (!tView)
    {
        tView = [[UILabel alloc] init];
        [tView setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.0]];
        
        [tView setTextColor:[UIColor whiteColor]];
        
        [tView setBackgroundColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:51/255.0f alpha:1.0f]];
        tView.textAlignment = NSTextAlignmentCenter;
        
        if (pickerView.tag == 1) {
            self.categoryTextField.text = [self.categoryPickerData[row] capitalizedString];
        } else if (pickerView.tag == 2) {
            self.groupTextField.text = [self.groupPickerData[row] capitalizedString];
        }
    }
    
    // Fill the label text here
    if (pickerView.tag == 1) {
        tView.text = [self.categoryPickerData[row] capitalizedString];
    } else if (pickerView.tag == 2) {
        tView.text = [self.groupPickerData[row] capitalizedString];
    }
    
    return tView;
}


-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    if (pickerView.tag == 1) {
        self.categoryTextField.text = [self.categoryPickerData[row] capitalizedString];
    } else if (pickerView.tag == 2) {
        self.groupTextField.text = [self.groupPickerData[row] capitalizedString];
    }
}


#pragma - UITextFieldDelegate Function

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"mapSegue"]) {
        AddErrandOnMapViewController *mapVC = (AddErrandOnMapViewController *)[segue destinationViewController];
        //mapVC.errandArray = self.errandArray;
        mapVC.errand = self.errand;
    }
}


#pragma mark - Geo

-(void)geoCodeAddress:(NSString*)address
{
    CLGeocoder *geoCoder = [[CLGeocoder alloc]init];
    [geoCoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if([placemarks count]) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            CLLocation *location = placemark.location;
            CLLocationCoordinate2D coordinate = location.coordinate;
            
            self.errand.coordinate = coordinate;
            self.errand.geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            [self saveErrand];
        } else {
            NSLog(@"location error");
            return;
        }
    }];
}

//check what text field is being edited.
- (IBAction)textFieldDidBeginEditing:(UITextField *)sender
{
    self.activeField = sender;
}


- (IBAction)textFieldDidEndEditing:(UITextField *)sender
{
    self.activeField = nil;
}


// move the scrol view up when the keboard appears
- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}


- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

@end
