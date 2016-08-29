//
//  ErrandListViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "ErrandListViewController.h"
#import "RunMyErrands-Swift.h"
#import "DetailViewController.h"
#import <Parse/Parse.h>
#import "Errand.h"
#import "GeoManager.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>


@interface ErrandListViewController () <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UILabel *helloUserLabel;
@property (weak, nonatomic) IBOutlet UILabel *youHaveErrandsLabel;
@property (nonatomic) NSArray *errandArray;
@property (nonatomic) GeoManager *locationManager;
@property (nonatomic) ErrandManager *errandManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) Scheduler *scheduler;
@property (weak, nonatomic) IBOutlet UILabel *noErrandsMessage1;
@property (weak, nonatomic) IBOutlet UILabel *noErrandsMessage2;
@property (weak, nonatomic) IBOutlet UILabel *noErrandsMessage3;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@end


@implementation ErrandListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //allow persmission for local notifications
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    // Do any additional setup after loading the view.
    self.tableview.tableFooterView = [[UIView alloc] init];
    [self.activitySpinner setHidesWhenStopped:YES];
    
    self.locationManager = [GeoManager sharedManager];
    [self.locationManager startLocationManager];

    self.errandManager = [ErrandManager new];
    self.scheduler = [Scheduler new];
    
    //Update tableView with pulldown
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableview addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];

    //subscribe to parse push notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushUpdate:) name:@"pushUpdate" object:nil];
    
    //Check if any errands were completed or active.
    [self.scheduler CreateActiveErrandsExpiryDate];
    [self.scheduler CreateCompletedErrandsExpiryDate];
    
    self.addButton.accessibilityLabel = @"Add New Errand";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self setGreeting];
    
    [self.activitySpinner startAnimating];
    
    //Check if any errands have expired.
    [self.scheduler CheckActiveErrandsExpiry];
    [self.scheduler CheckCompletedErrandsExpiry];
    self.addButton.enabled = NO;

    [self loadData];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
}

//Refresh table on parse push notification
- (void)pushUpdate:(NSNotification *)notification {
    [self loadData];
}

//Refresh table when pulled down.
- (void)refreshTable {
    [self.errandManager fetchData:^(BOOL success) {
        if (success) {
            [self.tableview reloadData];
            [self updatePushChannels];
            [self.refreshControl endRefreshing];
            
        }
    }];
}

-(void)loadData {
    [self.errandManager fetchData:^(BOOL success) {
        if (success) {
            [self.tableview reloadData];
            [self updatePushChannels];
        }
        
        [self.activitySpinner stopAnimating];
        self.addButton.enabled = YES;
        if ([self.errandManager isEmpty]) {
            self.noErrandsMessage1.hidden = NO;
            self.noErrandsMessage2.hidden = NO;
            self.noErrandsMessage3.hidden = NO;
        } else {
            self.noErrandsMessage1.hidden = YES;
            self.noErrandsMessage2.hidden = YES;
            self.noErrandsMessage3.hidden = YES;
        }
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updatePushChannels {
    PFUser *user = [PFUser currentUser];
    
    NSArray *channels;
    if ([user[@"pushNotify"] boolValue]) {
        channels = [self.errandManager fetchKeys];
    } else {
        channels = @[];
    }

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.channels = channels;
    [currentInstallation saveInBackground];
}

-(void) setGreeting {
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        self.helloUserLabel.text = [NSString stringWithFormat:@"%@, %@...", [self randHello], [[currentUser valueForKey:@"name"] capitalizedString]];
        self.youHaveErrandsLabel.text = [NSString stringWithFormat:@"%@", [self randWelcomeMessage]];
    } else {
    
    }
}

- (IBAction)logout:(UIBarButtonItem *)sender {
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
             @"Because yesterday you said tomorrow.",
             @"Just do it."][rand];
}

- (IBAction)addButton:(UIBarButtonItem *)sender {
    if ([self.errandManager isEmpty])
    {
        [self.tabBarController setSelectedIndex:3];
    }
    else
    {
        [self performSegueWithIdentifier:@"addNewErrand" sender:nil];
    }
}

#pragma mark - TableView Delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.errandManager fetchNumberOfRowsInSection:section];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.errandManager fetchNumberOfGroups];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ErrandsListTableViewCell *cell =(ErrandsListTableViewCell*)[self.tableview dequeueReusableCellWithIdentifier:@"errandListCell" forIndexPath:indexPath];
    
    cell.titleLabel.text = nil;
    cell.subtitleLabel.text = nil;
    cell.titleLabel.attributedText = nil;
    cell.subtitleLabel.attributedText = nil;
    cell.categoryImage.image = nil;
    cell.activeLabel.hidden = true;
    
    Errand *taskAtCell = [self.errandManager fetchErrand:indexPath];
    
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
    
    if ([taskAtCell.isActive boolValue]) {
        cell.activeLabel.hidden = false;
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
    if ([[segue identifier] isEqualToString:@"addNewErrand"]) {
//        AddErrandViewController *addNewErrandVC = (AddErrandViewController *)[segue destinationViewController];
//        addNewErrandVC.errandArray = self.errandArray;
        
    } else if ([[segue identifier] isEqualToString:@"showDetail"]) {
        DetailViewController *detailVC = (DetailViewController*)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableview indexPathForSelectedRow];
        Errand *selectedErrand = [self.errandManager fetchErrand:indexPath]; //self.taskArray[indexPath.section];
        detailVC.errand = selectedErrand;
    }
}


@end
