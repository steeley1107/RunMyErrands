//
//  MapViewController.m
//  RunMyErrandsMaps
//
//  Created by Steele on 2015-11-16.
//  Copyright © 2015 Steele. All rights reserved.
//

#import "MapViewController.h"
#import "GeoManager.h"
#import <Parse/Parse.h>

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) GeoManager *locationManager;
@property (nonatomic) BOOL didLoadLocations;


@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    
    self.didLoadLocations = NO;
    
    self.locationManager = [GeoManager sharedManager];
    [self.locationManager startLocationManager];
    self.mapView.showsUserLocation = true;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dropPinGesture:(UILongPressGestureRecognizer *)sender {
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [sender locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate =
        [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        self.task.coordinate = touchMapCoordinate;
        
        [self.mapView addAnnotation:self.task];
    }
}


-(void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    
    for (Task *task in self.taskArray) {
        //Determine if to track the task location.
        if (![task.isComplete boolValue]) {
            [self.mapView addAnnotation:task];
        }
    }
}


-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!self.didLoadLocations) {
        self.didLoadLocations = YES;
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.05;
        mapRegion.span.longitudeDelta = 0.05;
        [mapView setRegion:mapRegion animated: YES];
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if (![annotation isKindOfClass:[Task class]]) {
        return nil;
    }
    
    Task *task = (Task *) annotation;
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomDAnno"];
    
    if (!annotationView) {
        annotationView = task.annoView;
    }else {
        annotationView.annotation = annotation;
    }
    return annotationView;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

@end
