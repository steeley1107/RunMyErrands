//
//  AddNewTaskViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-15.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "AddNewTaskViewController.h"
#import <Parse/Parse.h>
#import "Task.h"
#import "RunMyErrands-Swift.h"

@interface AddNewTaskViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *taskNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationName;
@property (nonatomic) NSArray *groups;
@property (nonatomic) NSArray *categoryPickerData;
@property (nonatomic) NSMutableArray *groupPickerData;
@property (nonatomic) NSString *teamKey;
@property (nonatomic) Task* task;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UITextField *groupTextField;
@property (strong, nonatomic) UIPickerView *categoryPickerView;
@property (strong, nonatomic) UIPickerView *groupPickerView;
@end

@implementation AddNewTaskViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = false;
    
    self.categoryPickerData = @[@"General",@"Entertainment",@"Business",@"Food"];
    self.groupPickerData = [NSMutableArray new];
    [self fetchGroupPickerData];

    self.task = [Task object];
    self.task.isComplete = @NO;
    
    //code setup for picker view to popup when text is selected
    self.categoryPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
    [self.categoryPickerView setBackgroundColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:51/255.0f alpha:1.0f]];
    [self.categoryPickerView setDataSource: self];
    [self.categoryPickerView setDelegate: self];
    self.categoryPickerView.showsSelectionIndicator = YES;
    self.categoryPickerView.tag = 1;
    self.categoryTextField.inputView = self.categoryPickerView;
    
    self.groupPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
    [self.categoryPickerView setBackgroundColor:[UIColor colorWithRed:45/255.0 green:47/255.0 blue:51/255.0f alpha:1.0f]];
    [self.groupPickerView setDataSource: self];
    [self.groupPickerView setDelegate: self];
    self.groupPickerView.showsSelectionIndicator = YES;
    self.groupPickerView.tag = 2;
    self.groupTextField.inputView = self.groupPickerView;
 
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
}

-(void)fetchGroupPickerData {
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
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveButtonPressed:(UIButton *)sender {
    __block NSString *alertControllerTitle;
    __block NSString *alertControllerMessage;
    
    if (self.taskNameTextField.text.length == 0) {
        alertControllerTitle = @"Enter a Name";
        alertControllerMessage = @"Please Enter a Task Name";
        [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
    } else if (self.addressTextField.text.length == 0 && !self.task.longitude) {
        alertControllerTitle = @"Enter an Address";
        alertControllerMessage = @"Please Enter an Address or Choose it on the Map";
        [self presentAlertController:alertControllerTitle aMessage:alertControllerMessage];
    } else {
        self.task.title = [self.taskNameTextField.text capitalizedString];
        self.task.taskDescription = [self.descriptionTextField.text capitalizedString];
        self.task.subtitle = [self.locationName.text capitalizedString];
        self.task.category = @([self.categoryPickerView selectedRowInComponent:0]);
        
        self.task.isActive = @NO;

        NSNumber *groupChoice = @([self.groupPickerView selectedRowInComponent:0]);
        PFObject *group = self.groups[[groupChoice intValue]];
        self.task.group = group.objectId;
                
        if (self.addressTextField.text.length != 0) {
            self.task.address = self.addressTextField.text;
            [self geoCodeAddress:self.task.address];
        }else if (self.task.coordinate.latitude) {
            self.task.address = @"";
            [self saveTask];
        }
    }
}

-(void)saveTask {
    
    [self.task saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
            PFObject *group = self.groups[[self.groupPickerView selectedRowInComponent:0]];
            PFRelation *groupErrandsRelation = [group relationForKey:@"errands"];

            [groupErrandsRelation addObject:self.task];
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


-(void) presentAlertController:(NSString *)title aMessage:(NSString*)message {
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

- (IBAction)tapDetected:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}

#pragma - UIPickerView Delegate Functions

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
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
        //tView.numberOfLines=3;
    }
    
    // Fill the label text here
    if (pickerView.tag == 1) {
        tView.text = [self.categoryPickerData[row] capitalizedString];
    } else if (pickerView.tag == 2) {
        tView.text = [self.groupPickerData[row] capitalizedString];
    }
    
    return tView;
}


-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    if (pickerView.tag == 1) {
        self.categoryTextField.text = [self.categoryPickerData[row] capitalizedString];
        [self.categoryTextField resignFirstResponder];
    } else if (pickerView.tag == 2) {
        self.groupTextField.text = [self.groupPickerData[row] capitalizedString];
        [self.groupTextField resignFirstResponder];
    }
}

//- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    
//
//    NSString *title = @"sample title";
//    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//    
//    return attString;
//    
//}

#pragma - UITextFieldDelegate Function

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma - AddTaskDelegate Function

-(void)addTasksArray:(NSMutableArray*)array {
    self.taskArray = array;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"mapSegue"]) {
        AddTaskOnMapViewController *mapVC = (AddTaskOnMapViewController *)[segue destinationViewController];
        mapVC.taskArray = self.taskArray;
        mapVC.task = self.task;
    }
}

#pragma mark - Geo

-(void)geoCodeAddress:(NSString*)address {
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc]init];
    [geoCoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if([placemarks count]) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            CLLocation *location = placemark.location;
            CLLocationCoordinate2D coordinate = location.coordinate;
            
            self.task.coordinate = coordinate;
            self.task.geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            [self saveTask];
        } else {
            NSLog(@"location error");
            return;
        }
    }];
}

@end
