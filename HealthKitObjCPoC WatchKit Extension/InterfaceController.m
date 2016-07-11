//
//  InterfaceController.m
//  HealthKitObjCPoC WatchKit Extension
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "InterfaceController.h"
#import "InterfaceControllerSleep.h"
#import "SleepMilestoneInterfaceController.h"
@import HealthKit;

@interface InterfaceController() <InterfaceControllerSleepDelegate>


// HEALTHKIT PROPERTIES //

@property (nonatomic, retain) HKHealthStore *healthStore;

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


// INTERFACE ITEMS //

// Labels
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *inBedLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *sleepStartLabel;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceSeparator *separator;

@end


@implementation InterfaceController

- (instancetype)init {
    self = [super init];
    
    [self checkForPlist];
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    self.isSleeping = [self isSleepinProgress];
    
    [self clearAllMenuItems];
    
    // If sleep is currently in progress update labels and menu buttons to Sleep State
    if (self.isSleeping) {
        [self sleepInProgressWillReadDataFromPlist];
        [self updateLabelsWhileAsleep];
        [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(sleepDidStopMenuButton)];
        [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
        [self addMenuItemWithItemIcon:WKMenuItemIconResume title:@"Wake" action:@selector(userAwokeByUserMenuButton)];
        [self addMenuItemWithItemIcon:WKMenuItemIconMore title:@"Still Awake?" action:@selector(sleepWasDeferredByUserMenuButton)];
        NSLog(@"[VERBOSE] User is currently asleep. Resuming sleep state.");
        
    } else {
        [self updateLabelsWhileAwake];
        [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
//        [self addMenuItemWithItemIcon:WKMenuItemIconPlay title:@"Save" action:@selector(saveSleepDataToDataStore)];
//        [self addMenuItemWithItemIcon:WKMenuItemIconPlay title:@"Del" action:@selector(deleteSleepDataToDataStore)];
//        [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Add Data" action:@selector(populateHRData)];
    }
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

}

- (void)willActivate {
    [super willActivate];

    HKAuthorizationStatus hasAccessToSleepData = [self.healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    if (hasAccessToSleepData == 0) {
        NSLog(@"[VERBOSE] Sleeper does not have access to Health.app, prompting user for access.");
        [self requestAccessToHealthKit];
    }
    
}

- (void)didDeactivate {
    [super didDeactivate];
    
}

// PLIST METHODS //

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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSNumber *sleeping = [plistDictionary objectForKey:@"SleepInProgress"];
    BOOL thebool = [sleeping boolValue];
    NSLog(@"[VERBOSE] Users sleep status is %s.", thebool  ? "sleeping" : "awake");
    return thebool;
}

- (void)sleepInProgressWillReadDataFromPlist {
    NSLog(@"[VERBOSE] Sleep is currently in progress. Setting variables.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    self.inBedStart = [plistDictionary objectForKey:@"StartInBedDate"];
    self.sleepStart = [plistDictionary objectForKey:@"StartSleepDate"];
    self.awakeStart = [plistDictionary objectForKey:@"StartAwakeDate"];
    NSLog(@"[DEBUG] in bed = %@", self.inBedStart);
    NSLog(@"[DEBUG] sleep = %@", self.sleepStart);
}

- (void)writeSleepStartDataToPlist {
    NSLog(@"[VERBOSE] Attempting to write data to plist.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    NSNumber *sleeping = [[NSNumber alloc] initWithBool:self.isSleeping];
    [plistDictionary setObject:sleeping forKey:@"SleepInProgress"];
    [plistDictionary setObject:self.inBedStart forKey:@"StartInBedDate"];
    [plistDictionary setObject:self.sleepStart forKey:@"StartSleepDate"];
    [plistDictionary setObject:self.awakeStart forKey:@"StartAwakeDate"];
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to write data to plist.");
    }
}

- (void)writeSleepStopDataToPlist {
    NSLog(@"[VERBOSE] Clearing plist data.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    NSNumber *sleeping = [[NSNumber alloc] initWithBool:self.isSleeping];
    [plistDictionary setObject:sleeping forKey:@"SleepInProgress"];
    [plistDictionary setObject:[NSDate date] forKey:@"StartInBedDate"];
    [plistDictionary setObject:[NSDate date] forKey:@"StartSleepDate"];
    [plistDictionary setObject:[NSDate date] forKey:@"StartAwakeDate"];
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Clearing of data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to clear data from plist.");
    }
}

- (void)saveSleepDataToDataStore {
    NSLog(@"[VERBOSE] Attempting to write sleep data to data store.");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];

    NSMutableArray *milestoneTimes = [plistDictionary objectForKey:@"milestoneTimes"];
    
    NSArray *lastNightSleepTimes = [[NSArray alloc] initWithObjects:self.inBedStart, self.sleepStart, self.sleepStop, self.inBedStop, nil];
    
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

// MENU BUTTON METHODS //

- (IBAction)sleepDidStartMenuButton {
    self.inBedStart = [NSDate date];
    self.awakeStart = [NSDate date];
    self.sleepStart = [NSDate dateWithTimeInterval:1 sinceDate:[NSDate date]];
    self.isSleeping = YES;
    
    [self updateLabelsWhileAsleep];
    [self writeSleepStartDataToPlist];
    
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"End" action:@selector(sleepDidStopMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconResume title:@"Wake" action:@selector(userAwokeByUserMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconMore title:@"Still Awake?" action:@selector(sleepWasDeferredByUserMenuButton)];
    
    NSLog(@"[VERBOSE] User is in bed at %@ and asleep at %@", self.inBedStart, self.sleepStart);
}
- (IBAction)sleepDidStopMenuButton {
    self.inBedStop = [NSDate date];
    self.awakeStop = [NSDate date];
    self.isSleeping = NO;
    
    NSLog(@"[VERBOSE] User exited in bed at %@ and woke at %@", self.inBedStop, self.sleepStop);
    
    [self readHeartRateData];
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    
    [self writeSleepStopDataToPlist];
}

- (IBAction)sleepWasCancelledByUserMenuButton {
    self.inBedStop = [NSDate date];
    self.sleepStop = [NSDate date];
    self.awakeStop = [NSDate date];
    self.isSleeping = NO;
    NSLog(@"[VERBOSE] User cancelled sleep at %@", self.sleepStop);
    
    [self updateLabelsWhileAwake];
    
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    
    [self writeSleepStopDataToPlist];
    [self clearAllSleepValues];
    NSLog(@"[VERBOSE] Sleep data will not be written to Health.app.");
}

- (IBAction)userAwokeByUserMenuButton {
    self.sleepStop = [NSDate date];
    self.isSleeping = YES;
    NSLog(@"[VERBOSE] User awoke from sleep at %@", self.sleepStop);
}

- (IBAction)sleepWasDeferredByUserMenuButton {
    self.sleepStart = [NSDate date];
    [self updateLabelsWhileAsleep];
    NSLog(@"[VERBOSE] User is still awake at %@", self.sleepStart);
}


// HealthKit Methods

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

- (void)writeToHealthKit {
    HKCategoryType *categoryType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:categoryType
                                                                          value:HKCategoryValueSleepAnalysisAsleep
                                                                      startDate:self.sleepStart
                                                                        endDate:self.sleepStop];
    HKCategorySample *inBedSample = [HKCategorySample categorySampleWithType:categoryType
                                                                       value:HKCategoryValueSleepAnalysisInBed
                                                                   startDate:self.inBedStart
                                                                     endDate:self.inBedStop];
    HKCategorySample *awakeSample1 = [HKCategorySample categorySampleWithType:categoryType
                                                                       value:HKCategoryValueSleepAnalysisAwake
                                                                   startDate:self.awakeStart
                                                                     endDate:self.sleepStart];
    HKCategorySample *awakeSample2 = [HKCategorySample categorySampleWithType:categoryType
                                                                        value:HKCategoryValueSleepAnalysisAwake
                                                                    startDate:self.sleepStop
                                                                      endDate:self.awakeStop];
    
    NSArray *sampleArray = [NSArray arrayWithObjects:sleepSample, inBedSample, awakeSample1, awakeSample2, nil];
    
    
    
    [self.healthStore saveObjects:sampleArray withCompletion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed to write data to Health.app with error: %@", error);
        } else {
            [self clearAllSleepValues];
        }
    }];
}

- (void)readHeartRateData {
    NSDate *sampleStartDate = self.sleepStart;
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
            [self updateLabelsForConfirmation];
        });
    }];
    
    [self.healthStore executeQuery:query];
    
}


// LABEL CONFIGURATION //

- (void)updateLabelsWhileAwake {
    
    [self.mainLabel setHidden:false];
    [self.inBedLabel setHidden:true];
    [self.sleepStartLabel setHidden:true];
    [self.separator setHidden:true];
    
    NSLog(@"[VERBOSE] Labels set for awake.");
}

- (void)updateLabelsWhileAsleep {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.mainLabel setHidden:true];
    [self.inBedLabel setHidden:false];
    [self.sleepStartLabel setHidden:false];
    [self.separator setHidden:false];
    
    [self.inBedLabel setText:[dateFormatter stringFromDate:self.inBedStart]];
    [self.sleepStartLabel setText:[dateFormatter stringFromDate:self.sleepStart]];
    [self.separator setHidden:false];
    
    NSLog(@"[VERBOSE] Labels set for asleep.");
}

- (void)updateLabelsForConfirmation {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.mainLabel setHidden:true];
    [self.inBedLabel setHidden:true];
    [self.sleepStartLabel setHidden:true];
    [self.separator setHidden:true];
    
    if (self.proposedSleepStart == nil) {
        self.proposedSleepStart = self.sleepStart;
        NSLog(@"[DEBUG] Could not determine sleep start from user's heart rate data. Setting last defined sleep start time instead.");
    }
    
    [self presentControllerWithName:@"confirm" context:@{@"delegate" : self, @"time" : self.proposedSleepStart}];
    
    NSLog(@"[VERBOSE] Labels set for asleep.");
}


// DELEGATE FUNCTIONS //

- (void)proposedSleepStartDecision:(int)buttonValue {
    
    if (buttonValue == 1) {
        [self proposedSleepStartWasConfirmed];
    } else {
        [self proposedSleepStartWasDenied];
    }
}

- (void)proposedSleepStartWasConfirmed {
    self.sleepStart = self.proposedSleepStart;
    [self writeToHealthKit];
    [self updateLabelsWhileAwake];
    [self saveSleepDataToDataStore];
}

- (void)proposedSleepStartWasDenied {
    [self writeToHealthKit];
    [self updateLabelsWhileAwake];
    [self saveSleepDataToDataStore];
}


// TASK CLEAN UP //

-(void)clearAllSleepValues {
    self.sleepStart = nil;
    self.sleepStop = nil;
    self.proposedSleepStart = nil;
    self.awakeStart = nil;
    self.awakeStop = nil;
    self.inBedStart = nil;
    self.inBedStop = nil;
}


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


// VALUE DEBUG //

- (void)debugVals {
    NSLog(@"[DEBUG] sleepStart: %@", self.sleepStart);
    NSLog(@"[DEBUG] sleepStop: %@", self.sleepStop);
    NSLog(@"[DEBUG] proposedSleepStart: %@", self.proposedSleepStart);
    NSLog(@"[DEBUG] awakeStart: %@", self.awakeStart);
    NSLog(@"[DEBUG] awakeStop: %@", self.awakeStop);
    NSLog(@"[DEBUG] inBedStart: %@", self.inBedStart);
    NSLog(@"[DEBUG] inBedStop: %@", self.inBedStop);
}

@end
