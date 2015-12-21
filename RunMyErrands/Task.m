//
//  Task.m
//  RunMyErrandsMaps
//
//  Created by Steele on 2015-11-16.
//  Copyright © 2015 Steele. All rights reserved.
//

#import "Task.h"


@implementation Task

@dynamic title;
@dynamic subtitle;
@dynamic taskDescription;
@dynamic address;
@dynamic locationName;
@dynamic lattitude;
@dynamic longitude;
@dynamic isComplete;
@dynamic category;
@dynamic group;

@dynamic isActive;
@dynamic geoPoint;

+ (void)load {
    [self registerSubclass];
}

+ (NSString*)parseClassName {
    return @"Task";
}

-(CLLocationCoordinate2D) coordinate {
    CLLocationCoordinate2D newCoordinate = CLLocationCoordinate2DMake([self.lattitude doubleValue], [self.longitude doubleValue]);
    return newCoordinate;
}

-(void) updateCoordinate {
    self.coordinate = CLLocationCoordinate2DMake([self.lattitude doubleValue], [self.longitude doubleValue]);
}

-(void) setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    self.lattitude = @(newCoordinate.latitude);
    self.longitude = @(newCoordinate.longitude);
}


-(GMSMarker*) makeMarker {
    
    GMSMarker *marker = [GMSMarker markerWithPosition:[self coordinate]];
    marker.title = self.title;
    marker.snippet = self.subtitle;
    //marker.userData = self.category;
    
    return marker;
}


-(NSString*)imageName:(int)catagoryNumber {
    
    switch (catagoryNumber) {
        case 0:
            return @"runmyerrands";
        case 1:
            return @"die";
        case 2:
            return @"briefcase";
        case 3:
            return @"cart";
        default:
            return @"runmyerrands";
    }
}


@end
