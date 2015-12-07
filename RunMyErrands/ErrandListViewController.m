//
//  ErrandListViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "ErrandListViewController.h"
#import "RunMyErrands-Swift.h"
#import "AddNewTaskViewController.h"
#import "DetailViewController.h"
#import <Parse/Parse.h>
#import "Task.h"
#import "GeoManager.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>


@interface ErrandListViewController () <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UILabel *helloUserLabel;
@property (weak, nonatomic) IBOutlet UILabel *youHaveTasksLabel;
@property (nonatomic) NSArray *taskArray;
@property (nonatomic) GeoManager *locationManager;
@property (nonatomic) ErrandManager *errandManager;
@end


@implementation ErrandListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableview.tableFooterView = [[UIView alloc] init];
    
    self.locationManager = [GeoManager sharedManager];
    [self.locationManager startLocationManager];

    self.errandManager = [ErrandManager new];
    //[self.errandManager fetchData:self.tableview];
    [self.errandManager fetchDataNew:^(BOOL sucess) {
        if (sucess) {
            [self.tableview reloadData];
        }
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self setGreeting];
    //[self.errandManager fetchData:self.tableview];
    [self.errandManager fetchDataNew:^(BOOL sucess) {
        if (sucess) {
            [self.tableview reloadData];
        }
    }];

    
    PFUser *user = [PFUser currentUser];
    NSLog(@"%@", user.username);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setGreeting {
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        self.helloUserLabel.text = [NSString stringWithFormat:@"%@, %@...", [self randHello], [[currentUser valueForKey:@"name"] capitalizedString]];
        self.youHaveTasksLabel.text = [NSString stringWithFormat:@"%@", [self randWelcomeMessage]];
    } else {
    
    }
}

- (IBAction)logout:(UIButton *)sender {
    [PFUser logOut];
    [[FBSDKLoginManager new] logOut];
    
    [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
}

-(NSString*) randHello {
    int rand = arc4random() % 5;
    return @[@"Hello",
             @"Salutations",
             @"Bonjour",
             @"Greetings",
             @"Hi",
             @"Hello"][rand];
}

-(NSString*) randWelcomeMessage {
    int rand = arc4random() % 5;
    
    return @[@"Get to work.",
             @"Here are your tasks.",
             @"Today is a good day to finish a task.",
             @"Get it done.",
             @"Yesterday you said tomorrow.",
             @"Just do it."][rand];
}

- (IBAction)addButton:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"addNewTask" sender:nil];
}

#pragma mark - TableView Delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.errandManager fetchNumberOfRowsInSection:section];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.errandManager fetchNumberOfGroups];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ErrandsListTableViewCell *cell =(ErrandsListTableViewCell*)[self.tableview dequeueReusableCellWithIdentifier:@"tasklistCell" forIndexPath:indexPath];
    
    cell.titleLabel.text = nil;
    cell.subtitleLabel.text = nil;
    cell.titleLabel.attributedText = nil;
    cell.subtitleLabel.attributedText = nil;
    cell.categoryImage.image = nil;
    
    Task *taskAtCell = [self.errandManager fetchErrand:indexPath];
    
    NSString *imageName;
    switch ([taskAtCell.category intValue]) {
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
    
    if ([taskAtCell.isComplete boolValue]) {
    
        if (taskAtCell.title) {
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[taskAtCell.title capitalizedString]];
            [title addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, [title length])];
            cell.titleLabel.attributedText = title;
        }
        
        if (taskAtCell.subtitle) {
            NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[taskAtCell.subtitle capitalizedString]];
            [subtitle addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, [subtitle length])];
            cell.subtitleLabel.attributedText = subtitle;
        }
        
        imageName = [imageName stringByAppendingString:@"-grey"];
        
    } else {
        
        cell.titleLabel.text = [taskAtCell.title capitalizedString];
        cell.subtitleLabel.text = [taskAtCell.subtitle capitalizedString];
        
    }
    
    cell.categoryImage.image = [UIImage imageNamed:imageName];
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.errandManager fetchTitleForHeaderInSection:section];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"addNewTask"]) {
        AddNewTaskViewController *addNewTaskVC = (AddNewTaskViewController *)[segue destinationViewController];
        addNewTaskVC.taskArray = self.taskArray;
        
    } else if ([[segue identifier] isEqualToString:@"showDetail"]) {
        DetailViewController *detailVC = (DetailViewController*)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableview indexPathForSelectedRow];
        Task *selectedTask = [self.errandManager fetchErrand:indexPath]; //self.taskArray[indexPath.section];
        detailVC.task = selectedTask;
    }
}


#pragma mark - Geo

-(void)trackGeoRegions {
    
    [self.locationManager removeAllTaskLocation];
    for (Task *task in self.taskArray) {
        CLLocationCoordinate2D center = task.coordinate;
        CLRegion *taskRegion = [[CLCircularRegion alloc]initWithCenter:center radius:200.0 identifier:[NSString stringWithFormat:@"%@\n%@",task.title,task.subtitle]];
        taskRegion.notifyOnEntry = YES;
        
        //Determine if to track the task location.
        if (![task.isComplete boolValue]) {
            [self.locationManager addTaskLocation:taskRegion];
        }
    }
}

@end
