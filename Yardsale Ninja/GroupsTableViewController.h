//
//  GroupsTableViewController.h
//  Yardsale Ninja
//
//  Created by User on 3/14/14.
//  Copyright (c) 2014 Trevor Burbidge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FiltersPickerDelegate.h"

@interface GroupsTableViewController : UITableViewController <UITableViewDelegate>

@property (weak) id <FiltersPickerDelegate> delegate;

@end


