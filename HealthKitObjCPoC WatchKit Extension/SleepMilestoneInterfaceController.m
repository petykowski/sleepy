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

/**
 * @brief Contains the last saved sleep when using the WatchOS app
 */
@property (nonatomic, readwrite) SleepSession *lastSleepSession;

/**
 * @brief Contains the converted data of the last saved sleep session to be sent via WCSession
 */
@property (nonatomic, readwrite) NSDictionary *sleepSessionDataDictToSave;

@end

@implementation SleepMilestoneInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lastSleepSession = [[SleepSession alloc] init];
        
        // Initate WatchConnectivity
        if ([WCSession isSupported]) {
            self.connectedSession = [WCSession defaultSession];
            self.connectedSession.delegate = self;
            [self.connectedSession activateSession];
        }
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
}

- (void)willActivate {
    [super willActivate];
    
    self.sleepDataExsists = [self doesMilestoneDataExsist];
    BOOL isSleepInProgress = [self isSleepinProgress];
    
    if (self.sleepDataExsists && !isSleepInProgress) {
        [self hideNewUserMessage];
        [self getMilestoneTimes];
        [self updateMilestoneTableData];
        [self prepareMenuIconsForResendingSleepData];
    } else if (!self.sleepDataExsists){
        [self displayNewUserMessage];
    }
}

- (void)didDeactivate {
    [super didDeactivate];
}

-(BOOL)doesMilestoneDataExsist {
    _lastSleepSession = [Utility contentsOfPreviousSleepSession];
    
    if (!_lastSleepSession.inBed || !_lastSleepSession.inBed.count) {
        return false;
    }
    else {
       return true;
    }
}

- (BOOL)isSleepinProgress {
    BOOL sleepInProgress = _lastSleepSession.isSleepSessionInProgress;
    NSLog(@"[VERBOSE] Sleep session is %s in progress.", sleepInProgress  ? "currently" : "not");
    return sleepInProgress;
}


#pragma mark - TableView Methods

- (void)getMilestoneTimes {
    _lastNightTimes = [Utility convertAndPopulatePreviousSleepSessionDataForMilestone:_lastSleepSession];
}

- (void)updateMilestoneTableData {
    NSArray *titleArray = [NSArray arrayWithObjects:@"IN BED", @"ASLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", @"BACK TO BED", @"BACK TO SLEEP", @"AWAKE", @"OUT BED", nil];
    
    [self.milestoneTable setNumberOfRows:_lastNightTimes.count withRowType:@"main"];
    for (NSInteger i = 0; i < self.milestoneTable.numberOfRows; i++) {
        MilestoneRowController* theRow = [self.milestoneTable rowControllerAtIndex:i];
        [theRow.milestoneLabel setText:[titleArray objectAtIndex:i]];
        [theRow.milestoneTimeLabel setText:[_lastNightTimes objectAtIndex:i]];
    }
}


#pragma mark - New User Message

-(void)displayNewUserMessage {
    [self.userMsgLabel setHidden:false];
}

-(void)hideNewUserMessage {
    [self.userMsgLabel setHidden:true];
}


#pragma mark - Menu Icon Methods
- (void)prepareMenuIconsForResendingSleepData {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Resend Sleep Data to iOS" action:@selector(sendLastSleepSessionDataToiOSApp)];
}


#pragma mark - Watch Connectivity Methods

- (void)sendLastSleepSessionDataToiOSApp {
    _sleepSessionDataDictToSave = [self populateDictionaryWithLastSleepSessionData];
    [[WCSession defaultSession] sendMessage:_sleepSessionDataDictToSave
                               replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                                   NSLog(@"[DEBUG] Contents of reply: %@", replyMessage);
                               }
                               errorHandler:^(NSError *error) {
                                   NSLog(@"[DEBUG] ERROR: %@", error);
                               }
     ];
}

- (NSMutableDictionary *)populateDictionaryWithLastSleepSessionData{
    NSData *inBedData = [NSKeyedArchiver archivedDataWithRootObject:_lastSleepSession.inBed];
    NSData *sleepData = [NSKeyedArchiver archivedDataWithRootObject:_lastSleepSession.sleep];
    NSData *wakeData = [NSKeyedArchiver archivedDataWithRootObject:_lastSleepSession.wake];
    NSData *outBedData = [NSKeyedArchiver archivedDataWithRootObject:_lastSleepSession.outBed];
    
    NSMutableDictionary *sleepSessionDictionary = [[NSMutableDictionary alloc] init];
    [sleepSessionDictionary setObject:@"sendSleepSessionDataToiOSApp" forKey:@"Request"];
    [sleepSessionDictionary setObject:@"Sleep Session" forKey:@"name"];
    [sleepSessionDictionary setObject:[_lastSleepSession.outBed lastObject] forKey:@"creationDate"];
    [sleepSessionDictionary setObject:inBedData forKey:@"inBed"];
    [sleepSessionDictionary setObject:sleepData forKey:@"sleep"];
    [sleepSessionDictionary setObject:wakeData forKey:@"wake"];
    [sleepSessionDictionary setObject:outBedData forKey:@"outBed"];
    
    return sleepSessionDictionary;
}

- (void) session:(nonnull WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {
    //
}

- (void) sessionDidBecomeInactive:(nonnull WCSession *)session {
    //
}

- (void) sessionDidDeactivate:(nonnull WCSession *)session {
    //
}

@end
