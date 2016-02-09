//
//  LocationManager.m
//  RottenMangoes
//
//  Created by Steele on 2015-11-10.
//  Copyright © 2015 Steele. All rights reserved.
//

#import "GeoManager.h"
#import "RunMyErrands-Swift.h"

int const kUpdateGeoFenceDistance = 500;


@interface GeoManager ()

@property (nonatomic) BOOL updateInitialLocation;
@property (nonatomic) CLLocation * initialLoc;
@property (nonatomic) GeoFenceManager *fenceManager;
@end


@implementation GeoManager

+ (instancetype)sharedManager {
    static GeoManager *sharedLocationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[self alloc] init];
    });
    return sharedLocationManager;
}

- (id)init {
    if (self = [super init]) {
        self.updateInitialLocation = YES;
    }
    return self;
}


-(void)setUpLocationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = 10;
        //have to move 100m before location manager checks again
        
        _locationManager.delegate = self;
        [_locationManager requestAlwaysAuthorization];
    }
    [_locationManager startUpdatingLocation];
    
}


- (void)startLocationManager{
    if ([CLLocationManager locationServicesEnabled]) {
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            [self setUpLocationManager];
            
        }else if (!([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)){
            [self setUpLocationManager];
            
        }else{
            
            [self inLocationErrorNotification];
        }
    }
}

-(void)stopLocationManager{
    if ([CLLocationManager locationServicesEnabled]) {
        if (_locationManager) {
            [_locationManager stopUpdatingLocation];
        }
    }
}

-(void)locationManager:(nonnull CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    CLLocation * loc = [locations objectAtIndex: [locations count] - 1];
    
    
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    if (locationAge > 10.0){
        //NSLog(@"locationAge is %1.2f",locationAge);
        return;
    }
    
    if (loc.horizontalAccuracy < 0){
        //NSLog(@"loc.horizontalAccuracy is %1.2f",loc.horizontalAccuracy);
        return;
    }
    
    if (_currentLocation == nil || _currentLocation.horizontalAccuracy >= loc.horizontalAccuracy){
        _currentLocation = loc;
        
        if (loc.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            //[self stopLocationManager];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"locationUpdated" object:nil];
    }
    
    //Check for distance to reload geo fences.
    CLLocationDistance distance = [self.initialLoc distanceFromLocation:loc];

    if (kUpdateGeoFenceDistance < distance) {
        self.updateInitialLocation = YES;
    }
    if (self.updateInitialLocation) {
        self.initialLoc = [locations objectAtIndex: [locations count] - 1];
        self.fenceManager = [[GeoFenceManager alloc] init];
        [self.fenceManager GetDataForFence];
        self.updateInitialLocation = NO;
    }
}


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [_locationManager requestStateForRegion:region];
     //NSLog(@"didStartMonitoring %@",region);
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    //NSLog(@"monitoringDidFailForRegion %@ %@",error, region);
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    [self inLocationNotificationForRegion:region];
}


-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
    if (state == 1) {
           [self inLocationNotificationForRegion:region];
    }
}



-(void)addErrandLocation:(CLRegion*)region {
    
    [_locationManager startMonitoringForRegion:region];
}

-(void)removeErrandLocation:(CLRegion*)region {
    
    [_locationManager stopMonitoringForRegion:region];
}


-(void)removeAllErrandLocation {
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}


// Notify user that they are in the area
-(void)inLocationNotificationForRegion:(CLRegion *)region {
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.regionTriggersOnce = YES;
    localNotification.alertTitle = @"You are in the Area";
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = [NSString stringWithFormat:@" %@", region.identifier];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

// Notify user that there is something wrong
-(void)inLocationErrorNotification {
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.regionTriggersOnce = YES;
    localNotification.alertTitle = @"Location services are disabled, Please go into Settings > Privacy > Location to enable map functions";
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = @"";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}





-(long)monitoredRegions {

    return self.locationManager.monitoredRegions.count;
}



@end
