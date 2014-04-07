//
//  GroupsTableViewController.m
//  Yardsale Ninja
//
//  Created by User on 3/14/14.
//  Copyright (c) 2014 Trevor Burbidge. All rights reserved.
//

#import "GroupsTableViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#define GROUPS_SECTION 0
#define PAGES_SECTION 1

@interface GroupsTableViewController ()

@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) NSArray *pages;
@property (strong, nonatomic) NSMutableArray *selectedGroups;
@property (strong, nonatomic) NSMutableArray *selectedPages;

@end

@implementation GroupsTableViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.groups = [userDefaults objectForKey:@"groups"];
    self.pages = [userDefaults objectForKey:@"pages"];
    
    if([self.groups count] == 0 && [self.pages count] == 0) {
        [self fetchGroupsAndPagesWithInitiator:nil];
    }
    
    self.selectedGroups = [NSMutableArray arrayWithArray:[userDefaults objectForKey:@"selectedGroups"]];
    self.selectedPages = [NSMutableArray arrayWithArray:[userDefaults objectForKey:@"selectedPages"]];
    
    if(self.selectedGroups == nil) {
        self.selectedGroups = [[NSMutableArray alloc] initWithCapacity:5];
    }
    if(self.selectedPages == nil) {
        self.selectedPages = [[NSMutableArray alloc] initWithCapacity:5];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (IBAction)doneButtonClicked:(UIBarButtonItem *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:self.selectedGroups forKey:@"selectedGroups"];
    [userDefaults setObject:self.selectedPages forKey:@"selectedPages"];
    [userDefaults setObject:self.groups forKey:@"groups"];
    [userDefaults setObject:self.pages forKey:@"pages"];
    
    [userDefaults synchronize];
    
    [self.delegate doneButtonClicked];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case GROUPS_SECTION:
            return [self.groups count];
        case PAGES_SECTION:
            return [self.pages count];
        default:
            return 0;
    }
//    NSLog(@"user groups: %@", self.groups);

    return [self.groups count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case GROUPS_SECTION:
            return @"Groups";
        case PAGES_SECTION:
            return @"Pages";
        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];

    // Configure the cell...
    switch ([indexPath section]) {
        case GROUPS_SECTION:
            cell.textLabel.text = [[self.groups objectAtIndex:[indexPath item]] objectForKey:@"name"];
            break;
        case PAGES_SECTION:
            cell.textLabel.text = [[self.pages objectAtIndex:[indexPath item]] objectForKey:@"name"];
            break;
        default:
            break;
    }
    
    if([self groupOrPageIsSelectedAtIndexPath:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell setSelected:NO animated:NO];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if([indexPath section] == GROUPS_SECTION)
    {
        NSString *groupID = [[self.groups objectAtIndex:[indexPath item]] objectForKey:@"id"];
        if([self.selectedGroups containsObject:groupID]) {
            [self.selectedGroups removeObject:groupID];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else {
            [self.selectedGroups addObject:groupID];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else
    {
        NSString *pageID = [[self.pages objectAtIndex:[indexPath item]] objectForKey:@"id"];
        if([self.selectedPages containsObject:pageID]) {
            [self.selectedPages removeObject:pageID];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else {
            [self.selectedPages addObject:pageID];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    [cell setSelected:NO animated:YES];
}

-(bool) groupOrPageIsSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section]) {
        case GROUPS_SECTION:
            return [self.selectedGroups containsObject:[[self.groups objectAtIndex:[indexPath item]] objectForKey:@"id"]];
        case PAGES_SECTION:
            return [self.selectedPages containsObject:[[self.pages objectAtIndex:[indexPath item]] objectForKey:@"id"]];
        default:
            return false;
    }
}

- (IBAction)doRefresh:(UIRefreshControl *)sender {
    [self fetchGroupsAndPagesWithInitiator:sender];
}

-(void) fetchGroupsAndPagesWithInitiator:(UIRefreshControl *)sender
{
    //If sender is nil maybe want to show some other kind of loading thing.
    
    
    [FBRequestConnection startWithGraphPath:@"/me?fields=groups,likes" completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if(!error)
         {
             FBGraphObject *graphResult = (FBGraphObject*)result;
             
             NSDictionary *groupsWrap = [graphResult objectForKey:@"groups"];
             self.groups = [groupsWrap objectForKey:@"data"];
             
             NSDictionary *pagesWrap = [graphResult objectForKey:@"likes"];
             self.pages = [pagesWrap objectForKey:@"data"];
             
             [self.tableView reloadData];
             
             if(sender != nil) {
                 [sender endRefreshing];
             }
         }
     }];

}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
