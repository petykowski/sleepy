//
//  SleepMilestoneInterfaceController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepMilestoneInterfaceController.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "MilestoneRowController.h"
#import "Utility.h"

@interface SleepMilestoneInterfaceController () <WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *milestoneTable;
@property (nonatomic, readwrite) NSArray *lastNightTimes;
@property (nonatomic, readwrite) BOOL sleepDataExsists;
@property (nonatomic, readwrite) NSMutableArray *milestoneData;
@property (nonatomic, readwrite) BOOL isInitialLaunch;

// LABELS //
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *userMsgLabel;

@end

@implementation SleepMilestoneInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isInitialLaunch = true;
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    self.sleepDataExsists = [self doesMilestoneDataExsist];
    BOOL isSleepInProgress = [self isSleepinProgress];
    
    if (self.sleepDataExsists && _isInitialLaunch && !isSleepInProgress) {
        [self hideNewUserMessage];
        [self getMilestoneTimes];
        [self updateMilestoneTableData];
        _isInitialLaunch = false;
    } else if (!self.sleepDataExsists){
        [self displayNewUserMessage];
    }
    
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

- (BOOL)isSleepinProgress {
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    NSNumber *sleeping = [plistDictionary objectForKey:@"SleepInProgress"];
    BOOL thebool = [sleeping boolValue];
    return thebool;
}

- (void)getMilestoneTimes {
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    self.lastNightTimes = [Utility convertAndPopulateSleepSessionDataForMilestone:plistDictionary];
}

- (void)updateMilestoneTableData {
    NSArray *titleArray = [NSArray arrayWithObjects:@"IN BED", @"ASLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", nil];
    
    [self.milestoneTable setNumberOfRows:self.lastNightTimes.count withRowType:@"main"];
    for (NSInteger i = 0; i < self.milestoneTable.numberOfRows; i++) {
        MilestoneRowController* theRow = [self.milestoneTable rowControllerAtIndex:i];
        [theRow.milestoneLabel setText:[titleArray objectAtIndex:i]];
        [theRow.milestoneTimeLabel setText:[self.lastNightTimes objectAtIndex:i]];
    }
}

-(void)displayNewUserMessage {
    [self.userMsgLabel setHidden:false];
}

-(void)hideNewUserMessage {
    [self.userMsgLabel setHidden:true];
}

@end
