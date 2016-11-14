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
    
    self.errandNameLabel.text =  self.errand.title;
    self.errandDescriptionLabel.text = [NSString stringWithFormat:@"DESCRIPTION: %@", self.errand.errandDescription];
    self.locationNameLabel.text = [NSString stringWithFormat:@"WHERE: %@", self.errand.subtitle];
    self.addressLabel.text = [NSString stringWithFormat:@"ADDRESS: %@", self.errand.address];
    
    self.mapView.delegate = self;
    [self initiateMap];
}

- (void)viewWillAppear:(BOOL)animated {
    
    if ([self.errand.isComplete boolValue]) {
        self.completeButton.backgroundColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
        self.completeButton.enabled = false;
    }
    
    NSString *imageName = [self.errand imageName:[self.errand.category intValue]];
    
    //reload mapview
    [self.mapView clear];
    [self initiateMap];
    
    if ([self.errand.isComplete boolValue]) {
        imageName = [imageName stringByAppendingString:@"-grey"];
    }
    
    self.imageView.image = [UIImage imageNamed:imageName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)markAsComplete:(UIButton *)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"Errand"];
    [query getObjectInBackgroundWithId:self.errand.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        Errand *selectederrand = (Errand*)object;
        selectederrand.isComplete = @(YES);
        selectederrand.isActive = @(NO);
        selectederrand.completedDate = [selectederrand setCompletedErrandExpiryDate];
        
        [selectederrand saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                self.errand = selectederrand;
                self.completeButton.enabled = false;
                self.completeButton.backgroundColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
                
                PFUser *user = [PFUser currentUser];
                NSNumber *errandsCompleted = user[@"totalErrandsCompleted"];
                errandsCompleted = @(errandsCompleted.intValue + 1);
                user[@"totalErrandsCompleted"] = errandsCompleted;
                
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        
                        //New cloud push function
                        NSString *channels = self.errand.group;
                        NSString *message =[NSString stringWithFormat:@"%@ just completed Errand: %@", user[@"name"], self.errand.title];
                        
                        PFInstallation *installation = [PFInstallation currentInstallation];
                        [installation removeObject:self.errand.group forKey:@"channels"];
                        [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            [PFCloud callFunctionInBackground:@"iosPush" withParameters:@{@"channels":channels,@"deviceType":@"ios",@"text":message}];
                            [installation addUniqueObject:self.errand.group forKey:@"channels"];
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
    
    
    GMSMarker *marker = [GMSMarker markerWithPosition:self.errand.coordinate];
    
    marker.title = self.errand.title;
    marker.snippet = self.errand.subtitle;
    marker.userData = self.errand;
    marker.map = self.mapView;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:(self.errand.coordinate) zoom:14.0];
    self.mapView.camera = camera;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    
    CustomInfoWindow *infoWindow = [[[NSBundle mainBundle]loadNibNamed:@"CustomInfoWindow"
                                                                 owner:self
                                                               options:nil] objectAtIndex:0];
    
    infoWindow.title.text = marker.title;
    infoWindow.snippet.text = marker.snippet;
    
    Errand *errand = marker.userData;
    NSString *imageName = [errand imageName:errand.category.intValue];
    infoWindow.icon.image = [UIImage imageNamed:imageName];
    
    //auto size the width depending on title size or snippit.
    float x = infoWindow.frame.origin.x;
    float y = infoWindow.frame.origin.y;
    float textWidth = 0;
    
    float titleWidth = marker.title.length;
    float snippitWidth = marker.snippet.length;
    
    if (titleWidth > snippitWidth) {
        textWidth = titleWidth;
    }else {
        textWidth = snippitWidth;
    }
    
    float width = textWidth * 7.5 + 70;
    float height = infoWindow.frame.size.height;
    [infoWindow setFrame:CGRectMake(x, y, width, height)];
    
    [infoWindow layoutIfNeeded];
    
    return infoWindow;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"editErrand"]) {
        EditErrandViewController *editErrandVC = (EditErrandViewController *)[segue destinationViewController];
        editErrandVC.errand = self.errand;
    }
}


@end
