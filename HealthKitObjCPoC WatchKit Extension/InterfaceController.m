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

// TIMER //

@property (nonatomic, retain) NSTimer *deferredSleepOptionTimer;

// INTERFACE ITEMS //

// Images
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *wakeIndicator;

// Labels
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *inBedLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *sleepStartLabel;

// Groups
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *sleepSessionGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *inBedGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *stillAwakeGroup;

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
        [self updateLabelsForSleepSessionStart];
        [self prepareMenuIconsForUserAsleepInSleepSession];
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
    
}

- (void)didDeactivate {
    [super didDeactivate];
    
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

- (void)populateSleepSessionWithCurrentSessionData {
    self.currentSleepSession = [Utility contentsOfCurrentSleepSession];
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
    
    if (self.currentSleepSession.wake.count > 0) {
        [self.currentSleepSession.outBed addObject:[self.currentSleepSession.wake objectAtIndex:self.currentSleepSession.wake.count - 1]];
        [self fadeWakeIndicator];
    }
    
    [self.currentSleepSession.inBed addObject:[NSDate date]];
    [self.currentSleepSession.sleep addObject:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    self.currentSleepSession.isSleepSessionInProgress = true;
    
    [self updateLabelsForSleepSessionStart];
    [self writeCurrentSleepSessionToFile];
    
    [self prepareMenuIconsForUserAsleepInSleepSession];
    
    if (self.deferredSleepOptionTimer) {
        [self cancelTimer];
    }
    self.deferredSleepOptionTimer = [NSTimer scheduledTimerWithTimeInterval:kRemoveDeferredOptionTimer target:self selector:@selector(prepareMenuIconsForUserAsleepWithoutDeferredOption) userInfo:nil repeats:NO];
}

- (IBAction)sleepWasDeferredByUserMenuButton {
    
    [self.currentSleepSession.sleep replaceObjectAtIndex:self.currentSleepSession.sleep.count - 1 withObject:[NSDate date]];
    [self updateLabelsForSleepStartDeferred];
    [self writeCurrentSleepSessionToFile];
    
}

- (IBAction)userAwokeByUserMenuButton {
    
    [self displayWakeIndicator];
    [self.currentSleepSession.wake addObject:[NSDate date]];
    [self writeCurrentSleepSessionToFile];
    [self scheduleUserNotificationToEndSleepSession];
    [self cancelTimer];
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
    [self cancelTimer];
    [self prepareMenuIconsForUserNotInSleepSession];
    
    
}

- (IBAction)sleepWasCancelledByUserMenuButton {
    
    self.currentSleepSession.isSleepSessionInProgress = false;
    [self hideWakeIndicator];
    [self clearAllSleepValues];
    [self updateLabelsForSleepSessionEnded];
    [self cancelTimer];
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

#pragma mark - Watch Connectivity Methods

- (void)sendSleepSessionDataToiOSApp {
    
    _sleepSessionDataToSave = [self populateDictionaryWithSleepSessionData];
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

- (void)prepareMenuIconsForDebugging {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"HR Data" action:@selector(populateHRData)];
    [self addMenuItemWithImageNamed:@"sleepMenuIcon" title:@"Send Test Data" action:@selector(manuallySendTestDataToiOS)];
}


#pragma mark - Label Methods

- (void)updateLabelsForSleepSessionStart {
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    [self.mainLabel setHidden:true];
    [self.sleepSessionGroup setHidden:false];
    
    [self.inBedLabel setText:[dateFormatter stringFromDate:[self.currentSleepSession.inBed firstObject]]];
    [self.inBedGroup setHidden:false];
}

- (void)updateLabelsForSleepSessionEnded {
    
    [self.mainLabel setHidden:false];
    [self.sleepSessionGroup setHidden:true];
    [self.inBedGroup setHidden:true];
    [self.stillAwakeGroup setHidden:true];
}

- (void)updateLabelsForSleepStartDeferred {
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    [self.mainLabel setHidden:true];
    [self.sleepSessionGroup setHidden:false];
    [self.inBedLabel setText:[dateFormatter stringFromDate:[self.currentSleepSession.inBed firstObject]]];
    [self.sleepStartLabel setText:[dateFormatter stringFromDate:[self.currentSleepSession.sleep lastObject]]];
    [self.inBedGroup setHidden:false];
    [self.stillAwakeGroup setHidden:false];
}

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

#pragma mark - Image Methods

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

-(void)configureUserNotificationCenter {
    _notificationCenter.delegate = self;
    
    UNNotificationAction *endSleepSessionAction = [UNNotificationAction
                                                   actionWithIdentifier:@"END_ACTION"
                                                   title:@"End Session"
                                                   options:UNNotificationActionOptionForeground];
    
    UNNotificationAction *snoozeAction = [UNNotificationAction
                                          actionWithIdentifier:@"SNOOZE_ACTION"
                                          title:@"Snooze"
                                          options:UNNotificationActionOptionNone];
    
    UNNotificationCategory *endSleepSessionCategory = [UNNotificationCategory
                                                       categoryWithIdentifier:@"END_SLEEP_SESSION"
                                                       actions:@[endSleepSessionAction, snoozeAction]
                                                       intentIdentifiers:@[]
                                                       options:UNNotificationCategoryOptionNone];
    
    
    [_notificationCenter setNotificationCategories:[NSSet setWithObjects:endSleepSessionCategory, nil]];
}

-(void)scheduleUserNotificationToEndSleepSession {
    // Configure the notification content
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = kRemindUserToEndSleepSessionNotificationTitle;
    content.subtitle = kRemindUserToEndSleepSessionNotificationSubtitle;
    content.body = kRemindUserToEndSleepSessionNotificationBody;
    content.categoryIdentifier = @"END_SLEEP_SESSION";
    
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

-(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSLog(@"User responded to notification with %@", response.actionIdentifier);
    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        NSLog(@"User dismissed the notification");
    }
    else if ([response.actionIdentifier isEqualToString:@"SNOOZE_ACTION"]) {
        [self scheduleUserNotificationToEndSleepSession];
    }
    else if ([response.actionIdentifier isEqualToString:@"END_ACTION"]) {
        [self sleepDidStopMenuButton];
    }
}


#pragma mark - Sleep Delegate Functions

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
    [self updateLabelsForSleepSessionEnded];
    
    // Allows for proposed sleep interface to dismiss
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(reloadMilestoneInterfaceData)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - Reset Values

-(void)clearAllSleepValues {
    [self.currentSleepSession.inBed removeAllObjects];
    [self.currentSleepSession.sleep removeAllObjects];
    [self.currentSleepSession.wake removeAllObjects];
    [self.currentSleepSession.outBed removeAllObjects];
    self.proposedSleepStart = nil;
}

- (void)cancelTimer {
    [self.deferredSleepOptionTimer invalidate];
}


#pragma mark - iOS Simulator Health Data

- (void)populateHRData {
    int x = 0;
    int min = 50;
    int max = 62;
    
    NSDate *now = [NSDate date];
    
    while (x < 480) {
        
        double randomInt = min + arc4random_uniform(max - min + 1);
        
        HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKUnit *bpm = [HKUnit unitFromString:@"count/min"];
        HKQuantity *quantity = [HKQuantity quantityWithUnit:bpm doubleValue:randomInt];
        HKQuantitySample *quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:[now dateByAddingTimeInterval:1+(600*x)] endDate:[now dateByAddingTimeInterval:3+(600*x)]];
        
        NSArray *array = [NSArray arrayWithObjects:quantitySample, nil];
        
        [self.healthStore saveObjects:array withCompletion:^(BOOL success, NSError *error){
            if (!success) {
                NSLog(@"[DEBUG] Failed to write data to Health.app with error: %@", error);
            }
        }];
        
        x++;
    }
}


#pragma mark - Private Debug Methods

- (void)manuallySendTestDataToiOS {
    NSDate *inBedStart = [[NSDate alloc] initWithTimeIntervalSinceNow:1]; // now
    NSDate *inBedStop = [[NSDate alloc] initWithTimeIntervalSinceNow:900]; // 15 min from now
    NSDate *sleepStart = [[NSDate alloc] initWithTimeIntervalSinceNow:901]; // 15.01 min from now
    NSDate *sleepStop = [[NSDate alloc] initWithTimeIntervalSinceNow:14400]; // hours from now
    NSDate *wakeStart = [[NSDate alloc] initWithTimeIntervalSinceNow:14401];
    NSDate *wakeStop = [[NSDate alloc] initWithTimeIntervalSinceNow:14401];
    
    NSArray *inBedArray = [[NSArray alloc] initWithObjects:inBedStart, nil];
 
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
}

@end
