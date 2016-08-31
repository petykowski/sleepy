//
//  SessionsTableViewController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/25/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SessionsTableViewController : UITableViewController

// Core Data Objects 8/29
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
