//
//  SessionDetailTableViewController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/17/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "session.h"

@interface SessionDetailTableViewController : UITableViewController

@property (nonatomic, strong) session *sleepSession;

@end
