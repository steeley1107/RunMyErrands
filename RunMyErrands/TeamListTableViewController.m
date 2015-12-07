//
//  GroupListTableViewController.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-20.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "TeamListTableViewController.h"
#import <Parse/Parse.h>

@interface TeamListTableViewController () <UITableViewDelegate,UITableViewDataSource>
@property (nonatomic) NSArray *groups; //list of Groups
@property (nonatomic) NSMutableDictionary *groupMembers;
@end

@implementation TeamListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.allowsSelection = false;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    self.groupMembers = [NSMutableDictionary new];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self loadGroups];
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


//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 20;
//}

//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *headerView = [[UIView alloc] init];
//    headerView.backgroundColor = [UIColor clearColor];
//    return headerView;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupListCell" forIndexPath:indexPath];
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    
    PFObject *group = self.groups[indexPath.section];
    NSArray *membersArray = [self.groupMembers objectForKey:group.objectId];
    PFUser *user = membersArray[indexPath.row];
    cell.textLabel.text = [user[@"name"] capitalizedString];
    if ([user.objectId isEqualToString:group[@"teamLeader"]]) {
        cell.detailTextLabel.text = @"Lead";
    }
    return cell;
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
