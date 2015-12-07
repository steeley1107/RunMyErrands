//
//  DetailViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.taskNameLabel.text =  self.task.title;
    self.taskDescriptionLabel.text = [NSString stringWithFormat:@"DESCRIPTION: %@", self.task.taskDescription];
    self.locationNameLabel.text = [NSString stringWithFormat:@"WHERE: %@", self.task.subtitle];
    self.addressLabel.text = [NSString stringWithFormat:@"ADDRESS: %@", self.task.address];
    
    NSString *imageName;
    switch ([self.task.category intValue]) {
        case 0:
            imageName = @"runmyerrands";
            break;
        case 1:
            imageName = @"die";
            break;
        case 2:
            imageName = @"briefcase";
            break;
        case 3:
            imageName = @"cart";
            break;
        default:
            break;
    }
    
    if ([self.task.isComplete boolValue]) {
        imageName = [imageName stringByAppendingString:@"-grey"];
    }
    
    self.imageView.image = [UIImage imageNamed:imageName];
    
    self.mapView.delegate = self;
    [self initiateMap];
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
        self.task.isComplete = @(YES);
        [selectedTask saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self viewDidLoad];
            }
        }];
        
    }];
}


 #pragma mark - Geo

- (void) initiateMap {
 
        MKCoordinateRegion mapRegion;
        mapRegion.center = self.task.coordinate;
        mapRegion.span.latitudeDelta = 0.005;
        mapRegion.span.longitudeDelta = 0.005;
        [self.mapView setRegion:mapRegion animated: YES];
        [self.mapView addAnnotation:self.task];
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
@end
