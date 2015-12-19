//
//  DetailViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "DetailViewController.h"
#import <Parse/Parse.h>
#import "RunMyErrands-Swift.h"

@interface DetailViewController () <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.taskNameLabel.text =  self.task.title;
    self.taskDescriptionLabel.text = [NSString stringWithFormat:@"DESCRIPTION: %@", self.task.taskDescription];
    self.locationNameLabel.text = [NSString stringWithFormat:@"WHERE: %@", self.task.subtitle];
    self.addressLabel.text = [NSString stringWithFormat:@"ADDRESS: %@", self.task.address];
    
    self.mapView.delegate = self;
    [self initiateMap];
}

- (void)viewWillAppear:(BOOL)animated {
    
    if ([self.task.isComplete boolValue]) {
        self.completeButton.backgroundColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
        self.completeButton.enabled = false;
    }
    
    NSString *imageName = [self.task imageName:[self.task.category intValue]];
    
    if ([self.task.isComplete boolValue]) {
        imageName = [imageName stringByAppendingString:@"-grey"];
    }
    
    self.imageView.image = [UIImage imageNamed:imageName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)markAsComplete:(UIButton *)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"Task"];
    [query getObjectInBackgroundWithId:self.task.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        Task *selectedTask = (Task*)object;
        selectedTask.isComplete = @(YES);
        selectedTask.isActive = @(NO);
        
        [selectedTask saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                self.task = selectedTask;
                self.completeButton.enabled = false;
                self.completeButton.backgroundColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
                
                PFUser *user = [PFUser currentUser];
                NSNumber *errandsCompleted = user[@"totalErrandsCompleted"];
                errandsCompleted = @(errandsCompleted.intValue + 1);
                user[@"totalErrandsCompleted"] = errandsCompleted;
                
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        PFPush *push = [[PFPush alloc] init];
                        [push setChannel:self.task.group];
                        [push setMessage:[NSString stringWithFormat:@"%@ just completed Errand: %@", user[@"name"], self.task.title]];
                        
                        PFInstallation *installation = [PFInstallation currentInstallation];
                        [installation removeObject:self.task.group forKey:@"channels"];
                        [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            [push sendPushInBackground];
                            [installation addUniqueObject:self.task.group forKey:@"channels"];
                        }];
                        
                        [self viewWillAppear:true];
                    } else {
                        NSLog(@"Error: %@", error);
                    }
                }];
            }
        }];
        
    }];
}


#pragma mark - Geo

- (void) initiateMap {
    
    
    GMSMarker *marker = [GMSMarker markerWithPosition:self.task.coordinate];
    
    marker.title = self.task.title;
    marker.snippet = self.task.subtitle;
    marker.userData = self.task;
    marker.map = self.mapView;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:(self.task.coordinate) zoom:14.0];
    self.mapView.camera = camera;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    
    CustomInfoWindow *infoWindow = [[[NSBundle mainBundle]loadNibNamed:@"CustomInfoWindow"
                                                                 owner:self
                                                               options:nil] objectAtIndex:0];
    
    infoWindow.title.text = marker.title;
    infoWindow.snippit.text = marker.snippet;
    
    Task *task = marker.userData;
    NSString *imageName = [task imageName:task.category.intValue];
    infoWindow.icon.image = [UIImage imageNamed:imageName];
    
    [infoWindow layoutIfNeeded];

    return infoWindow;
}






@end
