//
//  FeedViewController.m
//  Yardsale Ninja
//
//  Created by Trevor Burbidge on 3/17/14.
//  Copyright (c) 2014 Trevor Burbidge. All rights reserved.
//

#import "FeedViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "GroupsTableViewController.h"

@interface FeedViewController ()

//@property (retain, nonatomic) GroupsTableViewController *groupsTableViewController;
@property (strong, nonatomic) NSArray *selectedGroups;

@property (strong, nonatomic) NSMutableDictionary *postsByID;
@property (strong, nonatomic) NSMutableArray *postIDs;
@property (strong, nonatomic) NSMutableArray *posts;

@property (strong, nonatomic) NSMutableDictionary *profilePicsByID;

@end

@implementation FeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [FBProfilePictureView class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.selectedGroups = [userDefaults objectForKey:@"selectedGroups"];
    
    
    if(self.postIDs == nil) {
        self.postIDs = [[NSMutableArray alloc] initWithCapacity:100];
    }
    if(self.postsByID == nil) {
        self.postsByID = [[NSMutableDictionary alloc] init];
    }
    if(self.posts == nil) {
        self.posts = [[NSMutableArray alloc] initWithCapacity:100];
    }
    if(self.profilePicsByID == nil) {
        self.profilePicsByID = [[NSMutableDictionary alloc] init];
    }
    
    if(FBSession.activeSession.isOpen) {
        [self fetchPostsWithInitiator:nil];
    }
    else if([FBSession openActiveSessionWithAllowLoginUI:NO])
    {
        [self fetchPostsWithInitiator:nil];
    }

}

-(void) updateSelectedGroups
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    self.selectedGroups = [userDefaults objectForKey:@"selectedGroups"];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Post" forIndexPath:indexPath];
    
    NSDictionary *post = [self.posts objectAtIndex:[indexPath item]];
    
    UILabel *name = (UILabel*)[cell viewWithTag:1];
    name.text = [[post objectForKey:@"from"] objectForKey:@"name"];
    
    UILabel *message = (UILabel*)[cell viewWithTag:2];
    message.text = [post objectForKey:@"message"];
    
    UIImageView *profilePicture = (UIImageView*)[cell viewWithTag:3];
    UIImage *image = [self.profilePicsByID objectForKey:[[post objectForKey:@"from"] objectForKey:@"id"]];
    profilePicture.image = image;
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.posts count];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated
{
    if (!FBSession.activeSession.isOpen) {
        if(![FBSession openActiveSessionWithAllowLoginUI:NO]) {
            [self performSegueWithIdentifier:@"ToLoginView" sender:self];
        }
//        else {
//            [self fetchPostsWithInitiator:nil];
//        }
//        [FBSession openActiveSessionWithReadPermissions:nil
//                                           allowLoginUI:YES
//                                      completionHandler:^(FBSession *session,
//                                                          FBSessionState state,
//                                                          NSError *error) {
//                                          if (error) {
//                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                                                  message:error.localizedDescription
//                                                                                                 delegate:nil
//                                                                                        cancelButtonTitle:@"OK"
//                                                                                        otherButtonTitles:nil];
//                                              [alertView show];
//                                          }
//                                      }];

    }
    
    
    //If no groups selected, go to groups page
//    [self performSegueWithIdentifier:@"ToGroups" sender:self];
    
}



-(void) doneButtonClicked
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
//    
//    if (!FBSession.activeSession.isOpen) {
//        if([FBSession openActiveSessionWithAllowLoginUI:NO]) {
//            [self fetchPostsWithInitiator:nil];
//        }
//    }
//    else {
    [self updateSelectedGroups];
    
    if (!FBSession.activeSession.isOpen) {
        if([FBSession openActiveSessionWithAllowLoginUI:NO]) {
            [self fetchPostsWithInitiator:nil];
        }
    }
    else {
        [self fetchPostsWithInitiator:nil];
    }
//    }
}

-(void) fetchPostsWithInitiator:(UIRefreshControl *)sender
{
    //If sender is nil maybe want to show some other kind of loading thing.
    NSMutableArray *requests = [[NSMutableArray alloc] initWithCapacity:[self.selectedGroups count]];
    for (NSString *groupID in self.selectedGroups) {
        NSString *graphPath = [NSString stringWithFormat:@"/%@?fields=feed.fields(from, message, updated_time)", groupID];
        [requests addObject:[FBRequest requestForGraphPath:graphPath]];
    }
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    __block int completedCount = 0;
    
    for (FBRequest *request in requests) {
        [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if(!error) {
                FBGraphObject *graphResult = (FBGraphObject*)result;
                
                //                NSLog(@"%@", result);
                NSArray *data = [[graphResult objectForKey:@"feed"] objectForKey:@"data"];
                
                //                NSLog(@"DATA******************%@", data);
                for (NSDictionary *post in data) {
                    NSString *userID = [[post objectForKey:@"from"] objectForKey:@"id"];
                    if([self.profilePicsByID objectForKey:userID] == nil) {
                        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", userID]];
                        NSData *picData = [NSData dataWithContentsOfURL:url];
                        UIImage *image = [UIImage imageWithData:picData];
                        [self.profilePicsByID setObject:image forKey:userID];
                    }
                    [self.posts addObject:post];
                    
                }
                
                completedCount++;
                
                if(completedCount == [requests count]) {
                    [self.posts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {                        return [[obj2 objectForKey:@"updated_time"] compare:[obj1 objectForKey:@"updated_time"]];
                    }];
                    
                    [self.collectionView reloadData];
                
                    if(sender != nil) {
                        [sender endRefreshing];
                    }
                }

            }
        }];
    }
    
    [self.posts removeAllObjects];
    
    [connection start];
    
//    NSString *groupID = [self.selectedGroups objectAtIndex:0];
//        NSString *graphPath = [NSString stringWithFormat:@"/%@?fields=feed.fields(from, message)", groupID];
//        [FBRequestConnection startWithGraphPath:graphPath completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//            if(!error)
//            {
//                FBGraphObject *graphResult = (FBGraphObject*)result;
//                
////                NSLog(@"%@", result);
//                NSArray *data = [[graphResult objectForKey:@"feed"] objectForKey:@"data"];
//                
////                NSLog(@"DATA******************%@", data);
//                for (NSDictionary *post in data) {
//                    NSString *postID = [post objectForKey:@"id"];
////                    NSLog(@"post: %@", postID);
//                    
//                    [self.postsByID setValue:post forKey:postID];
//                    [self.postIDs addObject:postID];
//                }
//                
//                [self.collectionView reloadData];
//                
//                if(sender != nil) {
//                    [sender endRefreshing];
//                }
//                
//            }
//        }];
//    }
    
//    [FBRequestConnection startWithGraphPath:@"/me?fields=groups,likes" completionHandler:
//     ^(FBRequestConnection *connection, id result, NSError *error) {
//         if(!error)
//         {
//             FBGraphObject *graphResult = (FBGraphObject*)result;
//             
//             NSDictionary *groupsWrap = [graphResult objectForKey:@"groups"];
//             self.groups = [groupsWrap objectForKey:@"data"];
//             
//             NSDictionary *pagesWrap = [graphResult objectForKey:@"likes"];
//             self.pages = [pagesWrap objectForKey:@"data"];
//             
//             [self.tableView reloadData];
//             
//             if(sender != nil) {
//                 [sender endRefreshing];
//             }
//         }
//     }];
    
}

//// Helper method to handle errors during API calls
//- (void)handleAPICallError:(NSError *)error
//{
//    // If the user has removed a permission that was previously granted
//    if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryPermissions) {
//        NSLog(@"Re-requesting permissions");
//        // Ask for required permissions.
//        [self requestPermission];
//        return;
//    }
//    
//    // Some Graph API errors need retries, we will have a simple retry policy of one additional attempt
//    // We also retry on a throttling error message, a more sophisticated app should consider a back-off period
//    retryCount++;
//    if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryRetry ||
//        [FBErrorUtility errorCategoryForError:error] == FBErrorCategoryThrottling) {
//        if (retryCount < 2) {
//            NSLog(@"Retrying open graph post");
//            // Recovery tactic: Call API again.
//            [self makeGraphAPICall];
//            return;
//        } else {
//            NSLog(@"Retry count exceeded.");
//            return;
//        }
//    }
//    
//    // For all other errors...
//    NSString *alertText;
//    NSString *alertTitle;
//    
//    // If the user should be notified, we show them the corresponding message
//    if ([FBErrorUtility shouldNotifyUserForError:error]) {
//        alertTitle = @"Something Went Wrong";
//        alertMessage = [FBErrorUtility userMessageForError:error];
//        
//    } else {
//        // show a generic error message
//        NSLog(@"Unexpected error posting to open graph: %@", error);
//        alertTitle = @"Something went wrong";
//        alertMessage = @"Please try again later.";
//    }
//    [self showMessage:alertText withTitle:alertTitle];
//}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier  isEqual: @"ToFiltersView"])
    {
        UINavigationController *navCon = (UINavigationController *)segue.destinationViewController;
        
        GroupsTableViewController *groupsCon = (GroupsTableViewController *)[[navCon childViewControllers] objectAtIndex:0];
        
        [groupsCon setDelegate:self];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
