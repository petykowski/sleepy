//
//  StatisticsTableViewController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/2/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface StatisticsTableViewController : UITableViewController

@property (nonatomic) HKHealthStore *healthStore;

@end
