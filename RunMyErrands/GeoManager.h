//
//  LocationManager.h
//  RottenMangoes
//
//  Created by Steele on 2015-11-10.
//  Copyright © 2015 Steele. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GeoManager : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong,nonatomic) CLLocation *currentLocation;

+ (instancetype)sharedManager;

-(void)setUpLocationManager;
- (void)startLocationManager;
-(void)stopLocationManager;
//-(void)locationManager:(nonnull CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations;
//- (void) initiateMap;
-(void)addTaskLocation:(CLRegion*)region;
-(void)removeTaskLocation:(CLRegion*)region;
-(void)removeAllTaskLocation;

@end
