//
//  ChartViewController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 11/13/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
#import "session.h"

@interface ChartViewController : UIViewController

@property (nonatomic) HKHealthStore *healthStore;

@property (nonatomic) NSArray *xAxisLabels;
@property (nonatomic) NSArray *yAxisLabels;

@property (nonatomic) NSString *chartTitle;

@property (nonatomic, strong) session *sleepSession;

@end
