//
//  InterfaceController.m
//  HealthKitObjCPoC WatchKit Extension
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "InterfaceController.h"
#import "InterfaceControllerSleep.h"
#import "SleepMilestoneInterfaceController.h"
#import "Utility.h"
#import "Constants.h"
#import "SleepSession.h"

@import HealthKit;
@import UserNotifications;

@interface InterfaceController() <InterfaceControllerSleepDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate>

// HEALTHKIT PROPERTIES //

@property (nonatomic, retain) HKHealthStore *healthStore;

// NOTIFICATION CENTER PROPERTIES //

@property (nonatomic, retain) UNUserNotificationCenter *notificationCenter;

// SLEEP SESSION //

@property (nonatomic, readwrite) SleepSession *currentSleepSession;
@property (nonatomic, readwrite) NSDate *proposedSleepStart;
@property (nonatomic, readwrite) NSDictionary *sleepSessionDataToSave;

// WATCH CONNECTIVITY //

@property (nonatomic, retain) WCSession *connectedSession;

// INTERFACE ITEMS //

// Images
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *wakeIndicator;
@property (strong, nonatomic) IBOutlet WKInterfaceImage *sleepRings;

// Labels
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *inBedLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *sleepStartLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *inBedDashboardLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *durationDashboardLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *eightHourDashboardLabel;

// Groups
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *sleepSessionGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *inBedGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *stillAwakeGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *inBedDashboardGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *durationDashboardGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *eightHourDashboardGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *componentsDashboardGroup;

@end


@implementation InterfaceController

#pragma mark - UIViewController

- (instancetype)init {
    self = [super init];
    
    _notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [self configureUserNotificationCenter];
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    [self checkForPlist];
    [self clearAllMenuItems];
    
    self.currentSleepSession = [[SleepSession alloc] init];
    self.currentSleepSession.isSleepSessionInProgress = [self isSleepSessionInProgress];
    
    // If sleep is currently in progress update labels and menu buttons to Sleep State
    if (self.currentSleepSession.isSleepSessionInProgress) {
        [self populateSleepSessionWithCurrentSessionData];
        [self updateLabelsForSleepSessionInProgress];
        [self determineMenuIconsToDisplay];
        NSLog(@"[VERBOSE] User is currently asleep. Resuming sleep state.");
    } else {
        [self updateLabelsForSleepSessionEnded];
        [self prepareMenuIconsForUserNotInSleepSession];
    }
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

}

- (void)willActivate {
    [super willActivate];
    
    // If sleep is currently in progress update labels and ring
    if (self.currentSleepSession.isSleepSessionInProgress) {
        [self updateLabelsForSleepSessionInProgress];
    }
    
    // Initate WatchConnectivity
    if ([WCSession isSupported]) {
        self.connectedSession = [WCSession defaultSession];
        self.connectedSession.delegate = self;
        [self.connectedSession activateSession];
    }

    HKAuthorizationStatus hasAccessToSleepData = [self.healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    if (hasAccessToSleepData == 0) {
        NSLog(@"[VERBOSE] Sleeper does not have access to Health.app, prompting user for access.");
        [self requestAccessToHealthKit];
    }
    
    [self determineMenuIconsToDisplay];
    
}

- (void)didDeactivate {
    [super didDeactivate];
    [self determineMenuIconsToDisplay];
}

- (void)reloadMilestoneInterfaceData {
    [WKInterfaceController reloadRootControllersWithNames:[NSArray arrayWithObjects:@"mainInterface",@"lastNightInterface", nil] contexts:[NSArray arrayWithObjects:@"", @"", nil]];
}

#pragma mark - Data Store Methods

- (void)checkForPlist {
    BOOL success;
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kSleepSessionFileNameForWatch];
    
    success = [fileManager fileExistsAtPath:filePath];
    
    if (!success) {
        BOOL didWrite;
        NSLog(@"[DEBUG] File not found in users documents directory.");
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Health" ofType:@"plist"];
        didWrite = [fileManager copyItemAtPath:path toPath:filePath error:&error];
        
        if (didWrite) {
            NSLog(@"[DEBUG] File Health.plist copied to users documents directory.");
        } else if (!didWrite) {
            NSLog(@"[DEBUG] Unable to create file, Health.plist, at users document directory. Failed with error: %@", error);
        }
    }
}

- (BOOL)isSleepSessionInProgress {
    SleepSession *theSession = [Utility contentsOfCurrentSleepSession];
    BOOL thebool = theSession.isSleepSessionInProgress;
    NSLog(@"[VERBOSE] Sleep session is %s in progress.", thebool  ? "currently" : "not");
    return thebool;
}

- (BOOL)isUserAwake {
    int inBedCount = [self.currentSleepSession.inBed count];
    int awakeCount = [self.currentSleepSession.wake count];
    
    NSLog(@"[DEBUG] inBedCount = %d", inBedCount);
    NSLog(@"[DEBUG] awakeCount = %d", awakeCount);
    
    return awakeCount == inBedCount && awakeCount > 0;
}

- (void)populateSleepSessionWithCurrentSessionData {
    self.currentSleepSession = [Utility contentsOfCurrentSleepSession];
}

- (void)writeRemoveDeferredSleepOptionDate {
    NSString *filePath = [Utility pathToSleepSessionDataFile];
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSDate *removeDeferredSleepOptionDate = [NSDate dateWithTimeIntervalSinceNow:kRemoveDeferredOptionTimer];
    
    [sleepSessionFile setObject:removeDeferredSleepOptionDate forKey:@"removeDeferredSleepOptionDate"];
    
    BOOL didWrite = [sleepSessionFile writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Date to remove sleep deferred option sucessfully written to file.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to file.");
    }
}

- (void)writeCurrentSleepSessionToFile {
    NSString *filePath = [Utility pathToSleepSessionDataFile];
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableDictionary *currentSleepSessionDictionary = [[NSMutableDictionary alloc] initWithDictionary:[sleepSessionFile objectForKey:@"Current Sleep Session"]];
    
    [currentSleepSessionDictionary setObject:[NSNumber numberWithBool:self.currentSleepSession.isSleepSessionInProgress]  forKey:@"isSleepSessionInProgress"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.inBed  forKey:@"inBed"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.sleep  forKey:@"sleep"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.wake  forKey:@"wake"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.outBed  forKey:@"outBed"];
    
    [sleepSessionFile setObject:currentSleepSessionDictionary forKey:@"Current Sleep Session"];
    
    NSLog(@"[DEBUG] POST ADD CONTENTS: %@", sleepSessionFile);
    
    BOOL didWrite = [sleepSessionFile writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Sleep Session sucessfully written to file.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to file.");
    }
}

- (void)writeCurrentSleepSessionAndRetainAsPreviousSleepSessionAtFile {
    NSString *filePath = [Utility pathToSleepSessionDataFile];
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableDictionary *currentSleepSessionDictionary = [[NSMutableDictionary alloc] initWithDictionary:[sleepSessionFile objectForKey:@"Current Sleep Session"]];
    
    [currentSleepSessionDictionary setObject:[NSNumber numberWithBool:self.currentSleepSession.isSleepSessionInProgress]  forKey:@"isSleepSessionInProgress"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.inBed  forKey:@"inBed"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.sleep  forKey:@"sleep"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.wake  forKey:@"wake"];
    [currentSleepSessionDictionary setObject:self.currentSleepSession.outBed  forKey:@"outBed"];
    
    [sleepSessionFile setObject:currentSleepSessionDictionary forKey:@"Current Sleep Session"];
    [sleepSessionFile setObject:currentSleepSessionDictionary forKey:@"Previous Sleep Session"];
    
    BOOL didWrite = [sleepSessionFile writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Sleep Session sucessfully written to file.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to file.");
    }
}

- (void)deleteSleepSessionDataFile {
    BOOL success;
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kSleepSessionFileNameForWatch];
    
    success = [fileManager fileExistsAtPath:filePath];
    
    if (success) {
        BOOL didWrite;
        NSLog(@"[DEBUG] File currently exsists at this path.");
        didWrite = [fileManager removeItemAtPath:filePath error:&error];
        
        if (didWrite) {
            NSLog(@"[DEBUG] Sucessfully deleted Health.plist.");
        } else if (!didWrite) {
            NSLog(@"[DEBUG] Failed to delete Health.plist");
        }
        
    }

}


#pragma mark - Menu Button Methods

- (IBAction)sleepDidStartMenuButton {
    
    // Validates to true if user is returning back to sleep
    if (self.currentSleepSession.wake.count > 0) {
        [self.currentSleepSession.outBed addObject:[self.currentSleepSession.wake objectAtIndex:self.currentSleepSession.wake.count - 1]];
        [self fadeWakeIndicator];
        [self cancelPendingNotifications];
        [self removeDeliveredNotifications];
    }
    
    [self.currentSleepSession.inBed addObject:[NSDate date]];
    [self.currentSleepSession.sleep addObject:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    self.currentSleepSession.isSleepSessionInProgress = true;
    
    [self updateLabelsForSleepSessionStart];
    [self writeCurrentSleepSessionToFile];
    
    [self prepareMenuIconsForUserAsleepInSleepSession];
    
    [self writeRemoveDeferredSleepOptionDate];
    
}

- (IBAction)sleepWasDeferredByUserMenuButton {
    
    [self.currentSleepSession.sleep replaceObjectAtIndex:self.currentSleepSession.sleep.count - 1 withObject:[NSDate date]];
    [self updateLabelsForSleepSessionInProgress];
    [self writeCurrentSleepSessionToFile];
    [self writeRemoveDeferredSleepOptionDate];
    
}

- (IBAction)userAwokeByUserMenuButton {
    
    [self displayWakeIndicator];
    [self.currentSleepSession.wake addObject:[NSDate date]];
    [self writeCurrentSleepSessionToFile];
    [self scheduleUserNotificationToEndSleepSession];
    [self prepareMenuIconsForUserAwakeInSleepSession];
}

- (IBAction)sleepDidStopMenuButton {
    
    [self hideWakeIndicator];
    [self.currentSleepSession.outBed addObject:[NSDate date]];
    self.currentSleepSession.isSleepSessionInProgress = false;
    if (self.currentSleepSession.wake.count != self.currentSleepSession.outBed.count) {
        [self.currentSleepSession.wake addObject:[NSDate dateWithTimeInterval:-1 sinceDate:[NSDate date]]];
    }
    [self writeCurrentSleepSessionToFile];
    [self readHeartRateData];
    [self cancelPendingNotifications];
    [self removeDeliveredNotifications];
    [self prepareMenuIconsForUserDismissedProposedSleepInterface];
    
}

- (IBAction)sleepWasCancelledByUserMenuButton {
    
    self.currentSleepSession.isSleepSessionInProgress = false;
    [self hideWakeIndicator];
    [self clearAllSleepValues];
    [self updateLabelsForSleepSessionEnded];
    [self cancelPendingNotifications];
    [self removeDeliveredNotifications];
    [self prepareMenuIconsForUserNotInSleepSession];
    [self writeCurrentSleepSessionToFile];
    
}


#pragma mark - HealthKit Methods

- (void)requestAccessToHealthKit {
    NSArray *readTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    NSArray *writeTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed attempt to request access to Health.app with error: %@", error);
        }
    }];
}

- (void)writeSleepSessionDataToHealthKit {
    NSMutableArray *sampleArray = [[NSMutableArray alloc] init];
    HKCategoryType *categoryType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    for (int i = 0; i <= [self.currentSleepSession.wake count]; i++) {
        HKCategorySample *awakeSample;
        if (i == 0) {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.currentSleepSession.inBed objectAtIndex:i]
                                                                             endDate:[self.currentSleepSession.sleep objectAtIndex:i]];
        } else if (i == [self.currentSleepSession.wake count]) {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.currentSleepSession.wake objectAtIndex:i-1]
                                                                             endDate:[self.currentSleepSession.outBed objectAtIndex:i-1]];
            
        } else {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.currentSleepSession.wake objectAtIndex:i-1]
                                                                             endDate:[self.currentSleepSession.sleep objectAtIndex:i]];
        }
        [sampleArray addObject:awakeSample];
    }
    
    for (int i = 0; i < [self.currentSleepSession.inBed count]; i++) {
        HKCategorySample *inBedSample = [HKCategorySample categorySampleWithType:categoryType
                                                                           value:HKCategoryValueSleepAnalysisInBed
                                                                       startDate:[self.currentSleepSession.inBed objectAtIndex:i]
                                                                         endDate:[self.currentSleepSession.outBed objectAtIndex:i]];
        HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType
                                                                           value:HKCategoryValueSleepAnalysisAsleep
                                                                       startDate:[self.currentSleepSession.sleep objectAtIndex:i]
                                                                         endDate:[self.currentSleepSession.wake objectAtIndex:i]];
        [sampleArray addObject:inBedSample];
        [sampleArray addObject:sleepSample];
    }
    
    [self.healthStore saveObjects:sampleArray withCompletion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed to write data to Health.app with error: %@", error);
        } else {
            [self clearAllSleepValues];
        }
    }];
}

- (void)readHeartRateData {
    NSDate *sampleStartDate = [self.currentSleepSession.sleep firstObject];
    NSDate *sampleEndDate = [NSDate dateWithTimeInterval:3600 sinceDate:sampleStartDate];
    
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:sampleStartDate endDate:sampleEndDate options:HKQueryOptionNone];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (!results) {
            NSLog(@"An error has occured. The error was: %@", error);
            abort();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            BOOL sleepDetected = false;
            
            for (HKQuantitySample *sample in results) {
                
                double heartRate = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
                NSDate *predetictedSleep = sample.startDate;
                
                
                if (heartRate <= 52 && sleepDetected == false) {
                    NSLog(@"[DEBUG] User fell asleep at %@ with a heart rate of %f bpm", predetictedSleep, heartRate);
                    self.proposedSleepStart = predetictedSleep;
                    sleepDetected = true;
                }
                
            };
            
            NSLog(@"[DEBUG] The results are: %@", results);
            [self presentControllerToConfirmProposedSleepTime];
        });
    }];
    
    [self.healthStore executeQuery:query];
}


#pragma mark - Proposed Sleep Delegate Functions

- (void)presentControllerToConfirmProposedSleepTime {
    if (self.proposedSleepStart == nil) {
        [self presentControllerWithName:@"User Input Sleep Start"
                                context:@{@"delegate" : self,
                                          @"time" : [_currentSleepSession.sleep firstObject],
                                          @"maxSleepStart" : [_currentSleepSession.wake firstObject]}];
    } else {
        [self presentControllerWithName:@"confirm"
                                context:@{@"delegate" : self,
                                          @"time" : self.proposedSleepStart}];
    }
}

- (void)proposedSleepStartDecision:(int)buttonValue SleepStartDate:(NSDate*)date {
    
    if (date) {
        [self.currentSleepSession.sleep replaceObjectAtIndex:0 withObject:date];
        [self performSleepSessionCloseout];
    } else if (buttonValue == 0) {
        [self presentControllerWithName:@"User Input Sleep Start" context:@{@"delegate" : self,
                                                                            @"time" : [_currentSleepSession.sleep firstObject],
                                                                            @"maxSleepStart" : [_currentSleepSession.wake firstObject]}];
    } else if (buttonValue == 1) {
        // Proposed Sleep Was Confirmed
        [self.currentSleepSession.sleep replaceObjectAtIndex:0 withObject:self.proposedSleepStart];
        [self performSleepSessionCloseout];
    }
}

- (void)performSleepSessionCloseout {
    if (self.connectedSession.reachable) {
        NSLog(@"[DEBUG] Session Available");
        [self sendSleepSessionDataToiOSApp];
    } else {
        NSLog(@"[DEBUG] Session Unavailable");
    }
    [self writeSleepSessionDataToHealthKit];
    [self writeCurrentSleepSessionAndRetainAsPreviousSleepSessionAtFile];
    [self prepareMenuIconsForUserNotInSleepSession];
    
    // Allows for proposed sleep interface to dismiss
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(reloadMilestoneInterfaceData)
                                   userInfo:nil
                                    repeats:NO];
}


#pragma mark - Watch Connectivity Methods

- (void)sendSleepSessionDataToiOSApp {
    
    _sleepSessionDataToSave = [self populateDictionaryWithSleepSessionData];
    [[WCSession defaultSession] sendMessage:_sleepSessionDataToSave
                               replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                                   NSLog(@"[DEBUG] Contents of reply: %@", replyMessage);
                               }
                               errorHandler:^(NSError *error) {
                                   //catch any errors here
                                   NSLog(@"[DEBUG] ERROR: %@", error);
                               }
     ];
}

- (void)requestMostRecentSleepSessionFromiOSApp {
    NSDictionary *applicationData = [NSDictionary dictionaryWithObject:@"getMostRecentSleepSessionForWatchOS" forKey:@"Request"];
    
    [[WCSession defaultSession] sendMessage:applicationData
                               replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                                   // Remove
                                   NSLog(@"[DEBUG] Contents of Dict: %@", replyMessage);
                                   [WKInterfaceController reloadRootControllersWithNames:[NSArray arrayWithObjects:@"mainInterface",@"lastNightInterface", nil] contexts:[NSArray arrayWithObjects:@"", replyMessage, nil]];
                               }
                               errorHandler:^(NSError * _Nonnull error) {
                                   NSLog(@"[DEBUG] ERROR: %@", error);
                               }
     ];
}

- (NSMutableDictionary *)populateDictionaryWithSleepSessionData{
    NSData *inBedData = [NSKeyedArchiver archivedDataWithRootObject:self.currentSleepSession.inBed];
    NSData *sleepData = [NSKeyedArchiver archivedDataWithRootObject:self.currentSleepSession.sleep];
    NSData *wakeData = [NSKeyedArchiver archivedDataWithRootObject:self.currentSleepSession.wake];
    NSData *outBedData = [NSKeyedArchiver archivedDataWithRootObject:self.currentSleepSession.outBed];
    
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


#pragma mark - Menu Icon Methods

- (void)determineMenuIconsToDisplay {
    NSString *filePath = [Utility pathToSleepSessionDataFile];
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSDate *removeDeferredSleepOptionDate = [sleepSessionFile objectForKey:@"removeDeferredSleepOptionDate"];
    
    BOOL isActiveSleepSession = [self isSleepSessionInProgress];
    BOOL isUserAwake = [self isUserAwake];
    
    NSLog(@"[DEBUG] isUserAwake = %d", isUserAwake);
    
    if ([Utility compare:[NSDate date] isLaterThan:removeDeferredSleepOptionDate] && isActiveSleepSession && !isUserAwake) {
        [self prepareMenuIconsForUserAsleepWithoutDeferredOption];
    } else if (isActiveSleepSession && isUserAwake) {
        [self prepareMenuIconsForUserAwakeInSleepSession];
    } else if (isActiveSleepSession) {
        [self prepareMenuIconsForUserAsleepInSleepSession];
    }
    
}

- (void)prepareMenuIconsForUserNotInSleepSession {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
}

- (void)prepareMenuIconsForUserAsleepInSleepSession {
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(sleepDidStopMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
    [self addMenuItemWithImageNamed:@"wakeMenuIcon" title:@"Wake" action:@selector(userAwokeByUserMenuButton)];
    [self addMenuItemWithImageNamed:@"stillAwakeMenuIcon" title:@"Still Awake?" action:@selector(sleepWasDeferredByUserMenuButton)];
}

-(void)prepareMenuIconsForUserAwakeInSleepSession {
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(sleepDidStopMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
    [self addMenuItemWithImageNamed:@"backToSleepMenuIcon" title:@"Back To Sleep" action:@selector(sleepDidStartMenuButton)];
}

- (void)prepareMenuIconsForUserAsleepWithoutDeferredOption {
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(sleepDidStopMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
    [self addMenuItemWithImageNamed:@"wakeMenuIcon" title:@"Wake" action:@selector(userAwokeByUserMenuButton)];
}

- (void)prepareMenuIconsForUserDismissedProposedSleepInterface {
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(presentControllerToConfirmProposedSleepTime)];
}

- (void)prepareMenuIconsForDebugging {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Populate Test Data" action:@selector(manuallySendTestDataToiOS)];
}


#pragma mark - Label Methods

- (void)updateLabelsForSleepSessionStart {
    NSDateFormatter *dateWithoutFormatter = [Utility dateFormatterForTimeLabelsWithoutAMPM];
    NSDate *inBedDate = [self.currentSleepSession.inBed firstObject];
    NSDate *eightHourDate = [NSDate dateWithTimeInterval:28800 sinceDate:inBedDate];
    NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:inBedDate];
    
    [self.mainLabel setHidden:true];
    
    int ringProgress = (secondsBetween * 100) / 28800;
    if (ringProgress > 100) {
        [_sleepRings setImageNamed:@"sleep-ring-animation-100"];
    } else {
        [_sleepRings setImageNamed:[NSString stringWithFormat:@"sleep-ring-animation-%d", ringProgress]];
    }
    
    [_sleepRings setHidden:false];
    [_inBedDashboardLabel setText:[dateWithoutFormatter stringFromDate:inBedDate]];
    [_durationDashboardLabel setText:[Utility timeFormatter:secondsBetween]];
    [_eightHourDashboardLabel setText:[dateWithoutFormatter stringFromDate:eightHourDate]];
    [_componentsDashboardGroup setHidden:false];
}

- (void)updateLabelsForSleepSessionInProgress {
    NSDateFormatter *dateWithoutFormatter = [Utility dateFormatterForTimeLabelsWithoutAMPM];
    NSDate *inBedDate = [self.currentSleepSession.inBed firstObject];
    NSDate *eightHourDate = [NSDate dateWithTimeInterval:28800 sinceDate:inBedDate];
    NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:inBedDate];
    
    [self.mainLabel setHidden:true];
    
    int ringProgress = (secondsBetween * 100) / 28800;
    if (ringProgress > 100) {
        [_sleepRings setImageNamed:@"sleep-ring-animation-100"];
    } else {
        [_sleepRings setImageNamed:[NSString stringWithFormat:@"sleep-ring-animation-%d", ringProgress]];
    }
    
    [_inBedDashboardLabel setText:[dateWithoutFormatter stringFromDate:inBedDate]];
    [_durationDashboardLabel setText:[Utility timeFormatter:secondsBetween]];
    [_eightHourDashboardLabel setText:[dateWithoutFormatter stringFromDate:eightHourDate]];
    
    [_sleepRings setHidden:false];
    [_componentsDashboardGroup setHidden:false];
}

- (void)updateLabelsForSleepSessionEnded {
    
    [self.mainLabel setHidden:false];
    
    [_componentsDashboardGroup setHidden:true];
    [_sleepRings setHidden:true];
}


#pragma mark - Image Methods

-(void)displaySleepRings {
    NSRange range = NSMakeRange(0, 7);
    [self.sleepRings setImageNamed:@"sleep-ring-animation-"];
    [self.sleepRings startAnimatingWithImagesInRange:range duration:5.0 repeatCount:10];

}

-(void)displayWakeIndicator{
    NSRange range = NSMakeRange(0, 11);
    [self.wakeIndicator setImageNamed:@"wakeIndicator"];
    [self.wakeIndicator setHeight:8.0];
    [self.wakeIndicator setWidth:8.0];
    [self.wakeIndicator setHidden:false];
    [self.wakeIndicator startAnimatingWithImagesInRange:range duration:0.8 repeatCount:1];
}
-(void)fadeWakeIndicator{
    NSRange range = NSMakeRange(10, 12);
    [self.wakeIndicator setImageNamed:@"wakeIndicator"];
    [self.wakeIndicator startAnimatingWithImagesInRange:range duration:0.8 repeatCount:1];
    [NSTimer scheduledTimerWithTimeInterval:0.8
                                     target:self
                                   selector:@selector(hideWakeIndicator)
                                   userInfo:nil
                                    repeats:NO];
    
}
-(void)hideWakeIndicator{
    [self.wakeIndicator setHidden:true];
}


#pragma mark - User Notifications

- (void)configureUserNotificationCenter {
    _notificationCenter.delegate = self;
    
    UNNotificationAction *endSleepSessionAction = [UNNotificationAction
                                                   actionWithIdentifier:kEndSleepSessionActionIdentifier
                                                   title:@"End Session"
                                                   options:UNNotificationActionOptionForeground];
    
    UNNotificationAction *snoozeAction = [UNNotificationAction
                                          actionWithIdentifier:kSnoozeActionIdentifier
                                          title:@"Snooze"
                                          options:UNNotificationActionOptionNone];
    
    UNNotificationCategory *endSleepSessionCategory = [UNNotificationCategory
                                                       categoryWithIdentifier:kEndSleepSessionCategoryIdentifier
                                                       actions:@[endSleepSessionAction, snoozeAction]
                                                       intentIdentifiers:@[]
                                                       options:UNNotificationCategoryOptionNone];
    
    
    [_notificationCenter setNotificationCategories:[NSSet setWithObjects:endSleepSessionCategory, nil]];
}

- (void)scheduleUserNotificationToEndSleepSession {
    // Configure the notification content
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = kRemindUserToEndSleepSessionNotificationTitle;
    content.subtitle = kRemindUserToEndSleepSessionNotificationSubtitle;
    content.body = kRemindUserToEndSleepSessionNotificationBody;
    content.sound = [UNNotificationSound defaultSound];
    content.categoryIdentifier = kEndSleepSessionCategoryIdentifier;
    
    // Configure the trigger
    NSTimeInterval timeInterval = kRemindUserToEndSleepSessionTimeIntervalInSeconds;
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:NO];
    
    // Assign UUID
    NSString *identifer = [Utility stringWithUUID];
    
    // Create the request object.
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifer
                                                                          content:content
                                                                          trigger:trigger];
    
    [_notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSLog(@"User responded to notification with %@ for notification %@", response.actionIdentifier, response.notification);
    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        NSLog(@"[VERBOSE] User dismissed the notification");
    }
    else if ([response.actionIdentifier isEqualToString:kSnoozeActionIdentifier]) {
        if (_currentSleepSession.isSleepSessionInProgress) {
            [self scheduleUserNotificationToEndSleepSession];
        } else {
            NSLog(@"[VERBOSE] %@ will not perform action, %@, because user is no longer sleeping.", response.notification, response.actionIdentifier);
        }
    }
    else if ([response.actionIdentifier isEqualToString:kEndSleepSessionActionIdentifier]) {
        if (_currentSleepSession.isSleepSessionInProgress) {
            [self sleepDidStopMenuButton];
        } else {
            NSLog(@"[VERBOSE] %@ will not perform action, %@, because user is no longer sleeping.", response.notification, response.actionIdentifier);
        }
    }
}

- (void)cancelPendingNotifications {
    [_notificationCenter removeAllPendingNotificationRequests];
}

- (void)removeDeliveredNotifications {
    [_notificationCenter removeAllDeliveredNotifications];
}


#pragma mark - Reset Values

-(void)clearAllSleepValues {
    [self.currentSleepSession.inBed removeAllObjects];
    [self.currentSleepSession.sleep removeAllObjects];
    [self.currentSleepSession.wake removeAllObjects];
    [self.currentSleepSession.outBed removeAllObjects];
    self.proposedSleepStart = nil;
}


#pragma mark - iOS Simulator Test Data Methods

- (void)manuallySendTestDataToiOS {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy.MM.dd G 'at' HH:mm:ss zzz";
    formatter.timeZone = [NSTimeZone localTimeZone];
    
    NSDate *inBedStart = [formatter dateFromString:@"2017.01.25 AD at 00:05:00 EST"];
    NSDate *sleepStart = [formatter dateFromString:@"2017.01.25 AD at 00:25:00 EST"];
    NSDate *sleepStop = [formatter dateFromString:@"2017.01.25 AD at 6:56:00 EST"];
    NSDate *wakeStop = [formatter dateFromString:@"2017.01.25 AD at 7:10:00 EST"];
    
    [_currentSleepSession.inBed addObject:inBedStart];
    [_currentSleepSession.sleep addObject:sleepStart];
    [_currentSleepSession.wake addObject:sleepStop];
    [_currentSleepSession.outBed addObject:wakeStop];
    
    NSDictionary *testDataToSave = [[NSDictionary alloc] init];
    testDataToSave = [self populateDictionaryWithSleepSessionData];
    [[WCSession defaultSession] sendMessage:testDataToSave
                               replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
                                   // Remove
                                   NSLog(@"[DEBUG] Contents of reply: %@", replyMessage);
                               }
                               errorHandler:^(NSError *error) {
                                   //catch any errors here
                                   NSLog(@"[DEBUG] ERROR: %@", error);
                               }
     ];
    
    [self populateHRDataFrom:inBedStart to:wakeStop rangingFrom:51 to:98];
}

- (void)populateHRDataFrom:(NSDate *)startDate to:(NSDate *)endDate rangingFrom:(int)minHeartRate to:(int)maxHeartRate {
    int x = 0;
    int min = minHeartRate;
    int max = maxHeartRate;
    
    NSMutableArray *arrayToSave = [[NSMutableArray alloc] init];
    
    while ([Utility compare:startDate isEarlierThanOrEqualTo:endDate]) {
        double randomInt = min + arc4random_uniform(max - min + 1);
        
        HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKUnit *bpm = [HKUnit unitFromString:@"count/min"];
        HKQuantity *quantity = [HKQuantity quantityWithUnit:bpm doubleValue:randomInt];
        HKQuantitySample *quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:[startDate dateByAddingTimeInterval:1+(300*x)] endDate:[startDate dateByAddingTimeInterval:3+(300*x)]];
        
        [arrayToSave addObject:quantitySample];
        
        x++;
        startDate = [NSDate dateWithTimeInterval:300 sinceDate:startDate];
    }
    
    [self.healthStore saveObjects:arrayToSave withCompletion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed to write data to Health.app with error: %@", error);
        }
    }];
}

@end
