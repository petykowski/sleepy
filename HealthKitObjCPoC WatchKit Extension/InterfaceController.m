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

@import HealthKit;

@interface InterfaceController() <InterfaceControllerSleepDelegate, WCSessionDelegate>


// HEALTHKIT PROPERTIES //

@property (nonatomic, retain) HKHealthStore *healthStore;

@property (nonatomic, retain) WCSession *connectedSession;

@property (nonatomic, readwrite) NSDictionary *sleepSessionDataToSave;

// Sleeping
@property (nonatomic, readwrite) BOOL isSleeping;

// In Bed
@property (nonatomic, readwrite) NSDate *inBedStart;
@property (nonatomic, readwrite) NSDate *inBedStop;

// Awake
@property (nonatomic, readwrite) NSDate *awakeStart;
@property (nonatomic, readwrite) NSDate *awakeStop;


// Asleep
@property (nonatomic, readwrite) NSDate *sleepStart;
@property (nonatomic, readwrite) NSDate *sleepStop;
@property (nonatomic, readwrite) NSDate *proposedSleepStart;


// Sleep Arrays

@property (nonatomic, readwrite) NSMutableArray *inBed;
@property (nonatomic, readwrite) NSMutableArray *sleep;
@property (nonatomic, readwrite) NSMutableArray *wake;
@property (nonatomic, readwrite) NSMutableArray *outBed;


// INTERFACE ITEMS //

// Images
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *wakeIndicator;

// Labels
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *inBedLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *sleepStartLabel;

// Groups
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *inBedGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *stillAwakeGroup;

@end


@implementation InterfaceController

#pragma mark - UIViewController

- (instancetype)init {
    self = [super init];
    
    self.inBed = [[NSMutableArray alloc] init];
    self.sleep = [[NSMutableArray alloc] init];
    self.wake = [[NSMutableArray alloc] init];
    self.outBed = [[NSMutableArray alloc] init];
    [self checkForPlist];
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    self.isSleeping = [self isSleepinProgress];
    
    [self clearAllMenuItems];
    
    // If sleep is currently in progress update labels and menu buttons to Sleep State
    if (self.isSleeping) {
        [self sleepInProgressWillReadDataFromPlist];
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
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    
    success = [fileManager fileExistsAtPath:filePath];
    
    if (!success) {
        BOOL didWrite;
        NSLog(@"[DEBUG] No file currently exsists at this path.");
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Health" ofType:@"plist"];
        didWrite = [fileManager copyItemAtPath:path toPath:filePath error:&error];
        
        if (didWrite) {
            NSLog(@"[DEBUG] Sucessfully created Health.plist.");
        } else if (!didWrite) {
            NSLog(@"[DEBUG] Failed to create Health.plist");
        }
        
    }
}

- (BOOL)isSleepinProgress {
    NSLog(@"[VERBOSE] Determining current sleep status.");
    
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    
    NSNumber *sleeping = [plistDictionary objectForKey:@"SleepInProgress"];
    BOOL thebool = [sleeping boolValue];
    NSLog(@"[VERBOSE] Users sleep status is %s.", thebool  ? "sleeping" : "awake");
    return thebool;
}

- (void)sleepInProgressWillReadDataFromPlist {
    NSLog(@"[VERBOSE] Sleep is currently in progress. Setting variables.");
    
    NSDictionary *plistDictionary = [Utility contentsOfHealthPlist];
    
    [self.inBed setArray:[plistDictionary objectForKey:@"inBedArray"]];
    [self.sleep setArray:[plistDictionary objectForKey:@"sleepArray"]];
    [self.wake setArray:[plistDictionary objectForKey:@"wakeArray"]];
    [self.outBed setArray:[plistDictionary objectForKey:@"outBedArray"]];
}

- (void)writeSleepDataToPlist {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    NSNumber *sleeping = [[NSNumber alloc] initWithBool:self.isSleeping];
    [plistDictionary setObject:sleeping forKey:@"SleepInProgress"];
    [plistDictionary setObject:self.inBed forKey:@"inBedArray"];
    [plistDictionary setObject:self.sleep forKey:@"sleepArray"];
    [plistDictionary setObject:self.wake forKey:@"wakeArray"];
    [plistDictionary setObject:self.outBed forKey:@"outBedArray"];
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to plist.");
    }
    
}

- (void)saveSleepDataToDataStore {
    NSLog(@"[VERBOSE] Attempting to write sleep data to data store.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];

    NSMutableArray *milestoneTimes = [plistDictionary objectForKey:@"milestoneTimes"];
    
    NSArray *lastNightSleepTimes = [[NSArray alloc] initWithObjects:[self.inBed firstObject], [self.sleep firstObject], [self.wake firstObject], [self.outBed firstObject], nil];
    
    if (milestoneTimes == nil) {
        milestoneTimes = [[NSMutableArray alloc] init];
    }
    
    [milestoneTimes addObjectsFromArray:lastNightSleepTimes];
    
    [plistDictionary setObject:milestoneTimes forKey:@"milestoneTimes"];
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to plist.");
    }
}

// ONLY CALL TO DELETE MILESTONE DATA //

- (void)deleteSleepDataToDataStore {
    NSLog(@"[VERBOSE] Attempting to delete sleep data to data store.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    [plistDictionary removeObjectForKey:@"milestoneTimes"];
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to plist.");
    }
}


#pragma mark - Menu Button Methods

- (IBAction)sleepDidStartMenuButton {
    if (self.wake.count > 0) {
        // Determines if this is the start of sleep or if user previously awoke during sleep session
        [self.outBed addObject:[self.wake objectAtIndex:self.wake.count - 1]];
        [self fadeWakeIndicator];
    }
    
    [self.inBed addObject:[NSDate date]];
    [self.sleep addObject:[NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]]];
    self.isSleeping = YES;

    [self updateLabelsForSleepSessionStart];
    [self writeSleepDataToPlist];
    
    [self prepareMenuIconsForUserAsleepInSleepSession];
}

- (IBAction)sleepDidStopMenuButton {
    [self hideWakeIndicator];
    [self.outBed addObject:[NSDate date]];
    
    if (self.wake.count == 0) {
        [self.wake addObject:[NSDate dateWithTimeInterval:-1 sinceDate:[NSDate date]]];
    }
    
    self.isSleeping = NO;
    
    [self writeSleepDataToPlist];
    [self readHeartRateData];
    [self prepareMenuIconsForUserNotInSleepSession];
    
}

- (IBAction)sleepWasCancelledByUserMenuButton {
    self.isSleeping = NO;
    [self hideWakeIndicator];
    
    [self clearAllSleepValues];
    [self updateLabelsForSleepSessionEnded];
    
    [self prepareMenuIconsForUserNotInSleepSession];
    
    [self writeSleepDataToPlist];
}

- (IBAction)userAwokeByUserMenuButton {
    [self displayWakeIndicator];
    [self.wake addObject:[NSDate date]];
    [self writeSleepDataToPlist];
    [self prepareMenuIconsForUserAwakeInSleepSession];
}

- (IBAction)sleepWasDeferredByUserMenuButton {
    [self.sleep replaceObjectAtIndex:self.sleep.count - 1 withObject:[NSDate date]];
    [self updateLabelsForSleepStartDeferred];
    [self writeSleepDataToPlist];
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
    
    for (int i = 0; i <= [self.wake count]; i++) {
        HKCategorySample *awakeSample;
        if (i == 0) {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.inBed objectAtIndex:i]
                                                                             endDate:[self.sleep objectAtIndex:i]];
        } else if (i == [self.wake count]) {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.wake objectAtIndex:i-1]
                                                                             endDate:[self.outBed objectAtIndex:i-1]];
            
        } else {
            awakeSample = [HKCategorySample categorySampleWithType:categoryType
                                                                               value:HKCategoryValueSleepAnalysisAwake
                                                                           startDate:[self.wake objectAtIndex:i-1]
                                                                             endDate:[self.sleep objectAtIndex:i]];
        }
        [sampleArray addObject:awakeSample];
    }
    
    for (int i = 0; i < [self.inBed count]; i++) {
        HKCategorySample *inBedSample = [HKCategorySample categorySampleWithType:categoryType
                                                                           value:HKCategoryValueSleepAnalysisInBed
                                                                       startDate:[self.inBed objectAtIndex:i]
                                                                         endDate:[self.outBed objectAtIndex:i]];
        HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType
                                                                           value:HKCategoryValueSleepAnalysisAsleep
                                                                       startDate:[self.sleep objectAtIndex:i]
                                                                         endDate:[self.wake objectAtIndex:i]];
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
    NSDate *sampleStartDate = [self.sleep firstObject];
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
    NSData *inBedData = [NSKeyedArchiver archivedDataWithRootObject:self.inBed];
    NSData *sleepData = [NSKeyedArchiver archivedDataWithRootObject:self.sleep];
    NSData *wakeData = [NSKeyedArchiver archivedDataWithRootObject:self.wake];
    NSData *outBedData = [NSKeyedArchiver archivedDataWithRootObject:self.outBed];
    
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


#pragma mark - Label Methods

- (void)updateLabelsForSleepSessionStart {
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    [self.mainLabel setHidden:true];
    
    [self.inBedLabel setText:[dateFormatter stringFromDate:[self.inBed firstObject]]];
    [self.inBedGroup setHidden:false];
}

- (void)updateLabelsForSleepSessionEnded {
    
    [self.mainLabel setHidden:false];
    [self.inBedGroup setHidden:true];
    [self.stillAwakeGroup setHidden:true];
}

- (void)updateLabelsForSleepStartDeferred {
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    [self.mainLabel setHidden:true];
    [self.inBedLabel setText:[dateFormatter stringFromDate:[self.inBed firstObject]]];
    [self.sleepStartLabel setText:[dateFormatter stringFromDate:[self.sleep lastObject]]];
    [self.inBedGroup setHidden:false];
    [self.stillAwakeGroup setHidden:false];
}

- (void)presentControllerToConfirmProposedSleepTime {
    if (self.proposedSleepStart == nil) {
        self.proposedSleepStart = [self.sleep firstObject];
        NSLog(@"[DEBUG] Could not determine sleep start from user's heart rate data. Setting last defined sleep start time instead.");
    }
    
    [self presentControllerWithName:@"confirm" context:@{@"delegate" : self, @"time" : self.proposedSleepStart}];
}

#pragma mark - Image Methods

-(void)displayWakeIndicator{
    NSRange range = NSMakeRange(0, 11);
    [self.wakeIndicator setImageNamed:@"wakeIndicator"];
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

#pragma mark - Sleep Delegate Functions

- (void)proposedSleepStartDecision:(int)buttonValue {
    
    if (buttonValue == 1) {
        // Proposed Sleep Was Confirmed
        [self.sleep replaceObjectAtIndex:0 withObject:self.proposedSleepStart];
    }
    
    [self performSleepSessionCloseout];
}

- (void)performSleepSessionCloseout {
    if (self.connectedSession.reachable) {
        NSLog(@"[DEBUG] Session Available");
        [self sendSleepSessionDataToiOSApp];
    } else {
        NSLog(@"[DEBUG] Session Unavailable");
    }
    [self writeSleepSessionDataToHealthKit];
    [self updateLabelsForSleepSessionEnded];
    [self saveSleepDataToDataStore];
    [self reloadMilestoneInterfaceData];
}

#pragma mark - Reset Values

-(void)clearAllSleepValues {
    [self.inBed removeAllObjects];
    [self.sleep removeAllObjects];
    [self.wake removeAllObjects];
    [self.outBed removeAllObjects];
    self.proposedSleepStart = nil;
}

#pragma mark - iOS Simulator Health Data

// ONLY CALL TO POPULATE DATA ON SIMULATOR //

- (void)populateHRData {
    int x = 0;
    int min = 50;
    int max = 60;
    
    NSDate *now = [NSDate date];
    
    while (x < 10) {
        
        double randomInt = min + arc4random_uniform(max - min + 1);
        
        HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKUnit *bpm = [HKUnit unitFromString:@"count/min"];
        HKQuantity *quantity = [HKQuantity quantityWithUnit:bpm doubleValue:randomInt];
        HKQuantitySample *quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:[now dateByAddingTimeInterval:600*x] endDate:[now dateByAddingTimeInterval:601*x]];
        
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

- (void)debugVals {
    NSLog(@"[DEBUG] sleepStart: %@", self.sleepStart);
    NSLog(@"[DEBUG] sleepStop: %@", self.sleepStop);
    NSLog(@"[DEBUG] proposedSleepStart: %@", self.proposedSleepStart);
    NSLog(@"[DEBUG] awakeStart: %@", self.awakeStart);
    NSLog(@"[DEBUG] awakeStop: %@", self.awakeStop);
    NSLog(@"[DEBUG] inBedStart: %@", self.inBedStart);
    NSLog(@"[DEBUG] inBedStop: %@", self.inBedStop);
}

- (void)debugArrays {
    NSLog(@"[DEBUG] Contents of inBed: %@", self.inBed);
    NSLog(@"[DEBUG] Contents of sleep: %@", self.sleep);
    NSLog(@"[DEBUG] Contents of wake: %@", self.wake);
    NSLog(@"[DEBUG] Contents of outBed: %@", self.outBed);
    
}

@end
