//
//  SleepMilestoneInterfaceController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepMilestoneInterfaceController.h"
#import "MilestoneRowController.h"
#import "Utility.h"

@interface SleepMilestoneInterfaceController ()

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *milestoneTable;
@property (nonatomic, readwrite) NSArray *lastNightTimes;
@property (nonatomic, readwrite) BOOL sleepDataExsists;
@property (nonatomic, readwrite) NSMutableArray *milestoneData;

// LABELS //
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *userMsgLabel;

@end

@implementation SleepMilestoneInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    if (context != nil) {
        self.milestoneData = [Utility convertAndPopulateSleepSessionDataForMilestone:context];
        [self updateMilestoneTableData:self.milestoneData];
    }
    
//    if (context != nil) {
//        self.sleepDataExsists = [self doesMilestoneDataExsist];
//        
//        if (self.sleepDataExsists) {
//            [self hideNewUserMessage];
//            [self getMilestoneTimes];
//            [self updateMilestoneTableData];
//        } else {
//            [self displayNewUserMessage];
//        }
//    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
//    self.sleepDataExsists = [self doesMilestoneDataExsist];
//    
//    if (self.sleepDataExsists) {
//        [self hideNewUserMessage];
//        [self getMilestoneTimes];
//        [self updateMilestoneTableData];
//    } else {
//        [self displayNewUserMessage];
//    }
    
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(BOOL)doesMilestoneDataExsist {
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    NSMutableArray *milestoneTimes = [plistDictionary objectForKey:@"milestoneTimes"];
    
    if (milestoneTimes) {
        return true;
    }
    else {
       return false;
    }
}

- (void)getMilestoneTimes {
    
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    
    NSMutableArray *milestoneTimes = [plistDictionary objectForKey:@"milestoneTimes"];
    NSMutableArray *formattedTimes = [[NSMutableArray alloc] init];
    
    NSRange endRange = NSMakeRange(milestoneTimes.count >= 4 ? milestoneTimes.count - 4 : 0, MIN(milestoneTimes.count, 4));
    NSArray *rawSleepData = [milestoneTimes subarrayWithRange:endRange];
    
    for (NSDate* rawTime in rawSleepData) {
        [formattedTimes addObject:[dateFormatter stringFromDate:rawTime]];
    }
    
    self.lastNightTimes = formattedTimes;
}

- (void)updateMilestoneTableData: (NSMutableArray*)sleepSessionData {
    NSArray *titleArray = [NSArray arrayWithObjects:@"IN BED", @"ASLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", nil];
    
    
    [self.milestoneTable setNumberOfRows:sleepSessionData.count withRowType:@"main"];
    for (int i = 0; i < self.milestoneTable.numberOfRows; i++) {
        MilestoneRowController* theRow = [self.milestoneTable rowControllerAtIndex:i];
        [theRow.milestoneLabel setText:[titleArray objectAtIndex:i]];
        [theRow.milestoneTimeLabel setText:[sleepSessionData objectAtIndex:i]];
    }
}

//- (void)updateMilestoneTableData {
//    NSArray *titleArray = [NSArray arrayWithObjects:@"IN BED", @"ASLEEP", @"AWAKE", @"END", nil];
//    
//    [self.milestoneTable setNumberOfRows:titleArray.count withRowType:@"main"];
//    for (NSInteger i = 0; i < self.milestoneTable.numberOfRows; i++) {
//        MilestoneRowController* theRow = [self.milestoneTable rowControllerAtIndex:i];
//        [theRow.milestoneLabel setText:[titleArray objectAtIndex:i]];
//        [theRow.milestoneTimeLabel setText:[self.lastNightTimes objectAtIndex:i]];
//    }
//}

-(void)displayNewUserMessage {
    [self.userMsgLabel setHidden:false];
}

-(void)hideNewUserMessage {
    [self.userMsgLabel setHidden:true];
}

@end
