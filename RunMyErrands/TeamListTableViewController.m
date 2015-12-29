//
//  GroupListTableViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-20.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "TeamListTableViewController.h"
#import <UIKit/UIKit.h>
#import "RunMyErrands-Swift.h"
#import <Parse/Parse.h>

@interface TeamListTableViewController () <UITableViewDelegate,UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic) NSArray *groups; //list of Groups
@property (nonatomic) NSMutableDictionary *groupMembers;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *listActivitySpinner;


@property NSCache *imageCache;
@end

@implementation TeamListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.allowsSelection = false;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.groupMembers = [NSMutableDictionary new];

    self.imageCache = [NSCache new];
    self.imageCache.countLimit = 20;
    
    
    //Update tableView with pulldown
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(loadGroups) forControlEvents:UIControlEventValueChanged];

    [self.listActivitySpinner setHidesWhenStopped:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    PFUser *user = [PFUser currentUser];
    NSLog(@"User: %@", user.username);
    self.usernameLabel.text = [user[@"name"] capitalizedString];
    self.userDetailLabel.text = [NSString stringWithFormat:@"Total Number of Errands Completed: %i", [user[@"totalErrandsCompleted"] intValue]];
    
    self.statusLabel.text = user[@"status"];
    
    PFFile *image = user[@"profile_Picture"];
    
    if (!image) {
        self.profileImageView.image = [UIImage imageNamed:@"runmyerrands-grey"];
    } else {
        [image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            
            self.profileImageView.layer.masksToBounds = YES;
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    self.profileImageView.image = [UIImage imageWithData:data];
                } else {
                    NSLog(@"Error: %@.", error);
                }
            });
        }];
    }
    
    [self loadGroups];
}


- (void)loadGroups {
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self.listActivitySpinner startAnimating];
        PFRelation *relation  = [currentUser relationForKey:@"memberOfTheseGroups"];
        [[relation query] findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (!error) {
                
                self.groups = objects;
                
                for (PFObject *object in self.groups) {
                    PFRelation *groupMembersRealtion = object[@"groupMembers"];
                    PFQuery *query = [groupMembersRealtion query];
                    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                        [self.groupMembers setObject:objects forKey:object.objectId];
                        [self.listActivitySpinner stopAnimating];
                        [self.tableView reloadData];
                    }];
                }
            }
            [self.refreshControl endRefreshing];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PFObject *group = self.groups[section];
    NSArray *membersArray = [self.groupMembers objectForKey:group.objectId];
    return membersArray.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    PFObject *group = self.groups[section];
    
    return [NSString stringWithFormat:@"%@ (id: %@)", [group[@"name"] capitalizedString], group.objectId];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectZero];
    sectionView.backgroundColor = [UIColor colorWithRed:86.0/255.0 green:113.0/255.0 blue:141.0/255.0f alpha:1.0f];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = section;
    [sectionView addSubview:button];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    PFObject *sectionGroup = self.groups[section];
    label.text = [sectionGroup[@"name"] capitalizedString];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [sectionView addSubview:label];
    
    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:sectionView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                            attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:sectionView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:10.0]];

    
    button.hidden = NO;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [button setTitle:@"Invite" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openMailClientForInvite:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:127.0/255.0 blue:0.0/255.0 alpha:1.0]];
    
    
    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:sectionView
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:button
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0 constant:10.0]];

    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:sectionView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:button
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0 constant:10.0]];

    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                            attribute:NSLayoutAttributeTrailingMargin
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:sectionView attribute:NSLayoutAttributeTrailingMargin
                                                           multiplier:1.0 constant:-10.0]];
    
    [sectionView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:sectionView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    NSLayoutConstraint *buttonHeight = [NSLayoutConstraint constraintWithItem:button
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:20.0];
    
    NSLayoutConstraint *buttonWidth = [NSLayoutConstraint constraintWithItem:button
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:60.0];
    
    [sectionView addConstraint:buttonHeight];
    [sectionView addConstraint:buttonWidth];
    
    return sectionView;
}

-(void) openMailClientForInvite:(id)sender {
    UIButton *button = (UIButton*)sender;
    
    PFUser *user = [PFUser currentUser];
    NSLog(@"%@", user.username);

    NSString *recipients = @"mailto:?subject=Join a 'Run My Errands Group'";
    PFObject *sectionGroup = self.groups[button.tag];
    
    NSString *body = [NSString stringWithFormat:@"&body=Hi,\n\n You've been invited to join my 'Run My Errands' group.  If you haven't heard of it, 'Run My Errands' is an errands manager that you can share with your friends, co-workers or whoever!\nYou can download it for free in the App Store.  When you're set up and logged in, go to 'groups' tab -> 'join' (top left button) and input the  Group ID# below:\n\n\nGroup ID# %@\n\n\n See you soon!\n\n-Run My Errands", sectionGroup.objectId];

    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];

    email = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSURL* mailURL = [NSURL URLWithString:email];

    if ([[UIApplication sharedApplication] canOpenURL:mailURL]) {
        [[UIApplication sharedApplication] openURL:mailURL];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    GroupListTableViewCell *cell = (GroupListTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"groupListCell" forIndexPath:indexPath];
    cell.nameLabel.text = @"";
    cell.leaderLabel.text = @"";
    //cell.profilePicture.image = [UIImage imageNamed:@"runmyerrands-grey"];
    
    PFObject *group = self.groups[indexPath.section];
    NSArray *membersArray = [self.groupMembers objectForKey:group.objectId];
    PFUser *user = membersArray[indexPath.row];
    cell.nameLabel.text = [user[@"name"] capitalizedString];
    if ([user.objectId isEqualToString:group[@"teamLeader"]]) {
        cell.leaderLabel.text = @"Lead";
    }

    cell.profilePicture.layer.masksToBounds = YES;
    cell.profilePicture.layer.cornerRadius = cell.profilePicture.layer.frame.size.width/2;
    
    UIImage *cachedImage = [self.imageCache objectForKey:user.objectId];
    
    //check cache first to see if an image exists in cache
    if (cachedImage) {
        //cached image exists
        dispatch_async(dispatch_get_main_queue(), ^{
                cell.profilePicture.image = cachedImage;
        });
    } else {
        //no cached image exists
        
        //check parse
        PFFile *image = user[@"profile_Picture"];
        
        if (!image) {
            //image doesn't exist in parse set it to placeholder
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.profilePicture.image = [UIImage imageNamed:@"runmyerrands-grey"];
            });
        } else {
            //image exists in parse
            [image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        cell.profilePicture.image = [UIImage imageWithData:data];
                        [self.imageCache setObject:[UIImage imageWithData:data] forKey:user.objectId];
                    } else {
                        NSLog(@"Error: %@.", error);
                    }
                });
            }];
        }
    }
    
    return cell;
}


#pragma mark - ImagePicker

- (IBAction)changeProfilePicture:(UITapGestureRecognizer *)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];

    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2;
    self.profileImageView.image = selectedImage;
    
    NSData *imageData = UIImageJPEGRepresentation(selectedImage, 0.25);
    PFFile *imageFile = [PFFile fileWithName:@"profile.jpg" data:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        PFUser *user = [PFUser currentUser];
        if (succeeded) {
            user[@"profile_Picture"] = imageFile;
            [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self.imageCache setObject:[UIImage imageWithData:imageData] forKey:user.objectId];
            }];
        } else {
            NSLog(@"Error: %@", error);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
