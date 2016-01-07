//
//  Task.h
//  RunMyErrandsMaps
//
//  Created by Steele on 2015-11-16.
//  Copyright © 2015 Steele. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
@import GoogleMaps;

@interface Task : PFObject <PFSubclassing>

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;
@property (nonatomic) NSString *taskDescription;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *locationName;
@property (nonatomic) NSNumber *longitude;
@property (nonatomic) NSNumber *lattitude;
@property (nonatomic) NSNumber *isComplete;
@property (nonatomic) NSNumber *category;
@property (nonatomic) NSString *group;
@property (nonatomic) NSNumber *isActive;
@property (nonatomic) PFGeoPoint *geoPoint;
@property (nonatomic) NSDate *activeDate;
@property (nonatomic) NSDate *completedDate;


+ (NSString*)parseClassName;
+ (void)load;
-(CLLocationCoordinate2D) coordinate;
-(void) setCoordinate:(CLLocationCoordinate2D)newCoordinate;
-(void) updateCoordinate;
-(GMSMarker*) makeMarker;
-(NSString*) imageName:(int)catagoryNumber;
-(NSDate*) setCompletedErrandExpiryDate;
-(NSDate*) setActiveErrandExpiryDate;

@end
