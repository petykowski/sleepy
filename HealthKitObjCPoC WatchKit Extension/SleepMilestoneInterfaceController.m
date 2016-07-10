//
//  SleepMilestoneInterfaceController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepMilestoneInterfaceController.h"
#import "MilestoneRowController.h"

@interface SleepMilestoneInterfaceController ()

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *milestoneTable;

@end

@implementation SleepMilestoneInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSArray *titleArray = [NSArray arrayWithObjects:@"IN BED", @"ASLEEP", @"AWAKE", @"END", nil];
    NSArray *timeArray = [NSArray arrayWithObjects:@"10:13 PM", @"10:37 PM", @"6:43 AM", @"6:54 AM", nil];
    
    [self.milestoneTable setNumberOfRows:titleArray.count withRowType:@"main"];
    for (NSInteger i = 0; i < self.milestoneTable.numberOfRows; i++) {
        MilestoneRowController* theRow = [self.milestoneTable rowControllerAtIndex:i];
        [theRow.milestoneLabel setText:[titleArray objectAtIndex:i]];
        [theRow.milestoneTimeLabel setText:[timeArray objectAtIndex:i]];
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



