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
@end

@implementation TeamListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.allowsSelection = false;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    self.groupMembers = [NSMutableDictionary new];

    PFUser *user = [PFUser currentUser];
    NSLog(@"User: %@", user.username);
    self.usernameLabel.text = [user[@"name"] capitalizedString];
    self.userDetailLabel.text = [NSString stringWithFormat:@"Total Number of Errands Completed: %i", [user[@"totalErrandsCompleted"] intValue]];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self loadGroups];
}

- (void)setProfilePicture {
    
    
}

- (void)loadGroups {
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        
        PFRelation *relation  = [currentUser relationForKey:@"memberOfTheseGroups"];
        [[relation query] findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (!error) {
                
                self.groups = objects;
                
                for (PFObject *object in self.groups) {
                    PFRelation *groupMembersRealtion = object[@"groupMembers"];
                    PFQuery *query = [groupMembersRealtion query];
                    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                        [self.groupMembers setObject:objects forKey:object.objectId];
                        [self.tableView reloadData];
                    }];
                }
            }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    GroupListTableViewCell *cell = (GroupListTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"groupListCell" forIndexPath:indexPath];
    cell.nameLabel.text = @"";
    cell.leaderLabel.text = @"";
    cell.profilePicture.image = [UIImage imageNamed:@"runmyerrands-grey"];
    
    PFObject *group = self.groups[indexPath.section];
    NSArray *membersArray = [self.groupMembers objectForKey:group.objectId];
    PFUser *user = membersArray[indexPath.row];
    cell.nameLabel.text = [user[@"name"] capitalizedString];
    if ([user.objectId isEqualToString:group[@"teamLeader"]]) {
        cell.leaderLabel.text = @"Lead";
    }

    PFFile *image = user[@"profile_Picture"];
    
    if (!image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.profilePicture.image = [UIImage imageNamed:@"runmyerrands-grey"];
        });
    } else {
        [image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {

            cell.profilePicture.layer.masksToBounds = YES;
            cell.profilePicture.layer.cornerRadius = cell.profilePicture.layer.frame.size.width/2;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    cell.profilePicture.image = [UIImage imageWithData:data];
                } else {
                    NSLog(@"Error: %@.", error);
                }
            });
        }];
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
    PFFile *imageFile = [PFFile fileWithData:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        PFUser *user = [PFUser currentUser];
        if (succeeded) {
            user[@"profile_Picture"] = imageFile;
            [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
            }];
        } else {
            NSLog(@"Error: %@", error);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    

}


/*

 func saveImage(user: PFUser) {
 
 if let image = self.profileImage.image,
 let imageData = UIImageJPEGRepresentation(image, 0.25),
 let imageFile = PFFile(name:"profile.jpg", data:imageData) {
 
 imageFile.saveInBackgroundWithBlock({ (bool: Bool, error:NSError?) -> Void in
 
 if bool {
 user["profile_Picture"] = imageFile
 user.saveInBackgroundWithBlock({ (Bool, ErrorType) -> Void in
 if (Bool) {
 print("save")
 } else {
 print("failed saving profile picture")
 }
 self.performSegueWithIdentifier("showSignupToTabBar", sender: nil)
 })
 }
 })
 }
 }

*/

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
