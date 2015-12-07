//
//  LocationManager.m
//  RottenMangoes
//
//  Created by Steele on 2015-11-10.
//  Copyright © 2015 Steele. All rights reserved.
//

#import "GeoManager.h"


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
            
            UIAlertController *alertController = [UIAlertController  alertControllerWithTitle:@"Location services are disabled, Please go into Settings > Privacy > Location to enable them for Play"  message:nil  preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            //      [self presentViewController:alertController animated:YES completion:nil];
            
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
}


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [_locationManager requestStateForRegion:region];
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    //NSLog(@"monitoringDidFailForRegion %@",error);
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    [self inLocationNotificationForRegion:region];
}


-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
    if (state == 1) {
        //   [self inLocationNotificationForRegion:region];
    }
}

-(void)addTaskLocation:(CLRegion*)region {
    
    [_locationManager startMonitoringForRegion:region];
}

-(void)removeTaskLocation:(CLRegion*)region {
    
    [_locationManager stopMonitoringForRegion:region];
}


-(void)removeAllTaskLocation {
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}


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



@end
