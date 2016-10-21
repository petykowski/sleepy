//
//  SleepInputInterfaceController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/20/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface SleepInputInterfaceController : WKInterfaceController

@end

@protocol SleepInputInterfaceControllerDelegate <NSObject>

- (void)proposedSleepStartDecision:(int)buttonValue SleepStartDate:(NSDate*)date;

@end
