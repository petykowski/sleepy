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
#import "SleepSession.h"

@interface SleepMilestoneInterfaceController () <WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *milestoneTable;
@property (nonatomic, readwrite) NSArray *lastNightTimes;
@property (nonatomic, readwrite) BOOL sleepDataExsists;
@property (nonatomic, readwrite) NSMutableArray *milestoneData;
@property (nonatomic, readwrite) BOOL isInitialLaunch;

// LABELS //
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *userMsgLabel;

// WATCH CONNECTIVITY //

@property (nonatomic, retain) WCSession *connectedSession;

@property (nonatomic, readwrite) SleepSession *lastSleepSession;
@property (nonatomic, readwrite) NSDictionary *sleepSessionDataToSave;

@end

@implementation SleepMilestoneInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
}

- (void)willActivate {
    [super willActivate];
    
    [self prepareMenuIconsForUserNotInSleepSession];
    
    // Initate WatchConnectivity
    if ([WCSession isSupported]) {
        self.connectedSession = [WCSession defaultSession];
        self.connectedSession.delegate = self;
        [self.connectedSession activateSession];
    }
    
    self.sleepDataExsists = [self doesMilestoneDataExsist];
    BOOL isSleepInProgress = [self isSleepinProgress];
    
    if (self.sleepDataExsists && !isSleepInProgress) {
        [self hideNewUserMessage];
        [self getMilestoneTimes];
        [self updateMilestoneTableData];
    } else if (!self.sleepDataExsists){
        [self displayNewUserMessage];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(BOOL)doesMilestoneDataExsist {
    SleepSession *previousSession = [Utility contentsOfPreviousSleepSession];
    
    if (!previousSession.inBed || !previousSession.inBed.count) {
        return false;
    }
    else {
       return true;
    }
}

- (BOOL)isSleepinProgress {
    SleepSession *theSession = [Utility contentsOfCurrentSleepSession];
    BOOL thebool = theSession.isSleepSessionInProgress;
    NSLog(@"[VERBOSE] Sleep session is %s in progress.", thebool  ? "currently" : "not");
    return thebool;
}

- (void)getMilestoneTimes {
    SleepSession *previousSession = [Utility contentsOfPreviousSleepSession];
    self.lastNightTimes = [Utility convertAndPopulatePreviousSleepSessionDataForMilestone:previousSession];
    NSLog(@"[DEBUG] from milestone: %@", self.lastNightTimes);
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

#pragma mark - Menu Icon Methods
- (void)prepareMenuIconsForUserNotInSleepSession {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Resend Sleep Data to iPhone" action:@selector(sendLastSleepSessionDataToiOSApp)];
}

#pragma mark - Watch Connectivity Methods

- (void)sendLastSleepSessionDataToiOSApp {
    self.lastSleepSession = [Utility contentsOfPreviousSleepSession];
    _sleepSessionDataToSave = [self populateDictionaryWithLastSleepSessionData];
    [[WCSession defaultSession] sendMessage:_sleepSessionDataToSave
                               replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                                   // Remove
                                   NSLog(@"[DEBUG] Contents of reply: %@", replyMessage);
                               }
                               errorHandler:^(NSError *error) {
                                   //catch any errors here
                                   NSLog(@"[DEBUG] ERROR: %@", error);
                               }
     ];
}

- (NSMutableDictionary *)populateDictionaryWithLastSleepSessionData{
    NSData *inBedData = [NSKeyedArchiver archivedDataWithRootObject:self.lastSleepSession.inBed];
    NSData *sleepData = [NSKeyedArchiver archivedDataWithRootObject:self.lastSleepSession.sleep];
    NSData *wakeData = [NSKeyedArchiver archivedDataWithRootObject:self.lastSleepSession.wake];
    NSData *outBedData = [NSKeyedArchiver archivedDataWithRootObject:self.lastSleepSession.outBed];
    
    NSMutableDictionary *sleepSessionDictionary = [[NSMutableDictionary alloc] init];
    [sleepSessionDictionary setObject:@"sendSleepSessionDataToiOSApp" forKey:@"Request"];
    [sleepSessionDictionary setObject:@"Sleep Session" forKey:@"name"];
    [sleepSessionDictionary setObject:[NSDate date] forKey:@"creationDate"];
    [sleepSessionDictionary setObject:inBedData forKey:@"inBed"];
    [sleepSessionDictionary setObject:sleepData forKey:@"sleep"];
    [sleepSessionDictionary setObject:wakeData forKey:@"wake"];
    [sleepSessionDictionary setObject:outBedData forKey:@"outBed"];
    
    return sleepSessionDictionary;
}

@end
