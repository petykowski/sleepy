//
//  InterfaceController.m
//  HealthKitObjCPoC WatchKit Extension
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "InterfaceController.h"
@import HealthKit;


@interface InterfaceController()

@property (nonatomic, retain) HKHealthStore *healthStore;

@property (nonatomic, readwrite) NSDate *sleepStart;
@property (nonatomic, readwrite) NSDate *sleepStop;

@property (nonatomic, readwrite) NSDate *inBedStart;
@property (nonatomic, readwrite) NSDate *inBedStop;

@property (nonatomic, readwrite) BOOL isSleeping;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@end


@implementation InterfaceController

- (instancetype)init {
    self = [super init];
    
    [self checkForPlist];
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    self.isSleeping = [self isSleepinProgress];
    
    [self clearAllMenuItems];
    
    // If sleep is currently in progress update our labels.
    if (self.isSleeping) {
        [self sleepInProgressWillReadDataFromPlist];
        [self updateLabels];
        [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"Wake" action:@selector(sleepDidStopMenuButton)];
        [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
        [self addMenuItemWithItemIcon:WKMenuItemIconResume title:@"Still Awake?" action:@selector(sleepWasDeferredByUserMenuButton)];
        NSLog(@"[VERBOSE] User is currently asleep. Resuming sleep state.");
        
    } else {
        [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
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
    
    if (self.isSleeping) {
#warning Need to write dates to plist.
    }
    
}

// .plist Methods

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
    
    BOOL didWrite = [plistDictionary writeToFile:filePath atomically:YES];
    if (didWrite) {
        NSLog(@"[VERBOSE] Clearing of data sucessfully written to plist.");
    } else {
        NSLog(@"[DEBUG] Failed to clear data from plist.");
    }
}


// Button Methods

- (IBAction)sleepDidStartMenuButton {
    self.inBedStart = [NSDate date];
    self.sleepStart = [NSDate date];
    self.isSleeping = YES;
    
    [self updateLabels];
    [self writeSleepStartDataToPlist];
    
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAccept title:@"Wake" action:@selector(sleepDidStopMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconBlock title:@"Cancel" action:@selector(sleepWasCancelledByUserMenuButton)];
    [self addMenuItemWithItemIcon:WKMenuItemIconResume title:@"Still Awake?" action:@selector(sleepWasDeferredByUserMenuButton)];
    
    NSLog(@"[VERBOSE] User is in bed at %@ and asleep at %@", self.inBedStart, self.sleepStart);
}
- (IBAction)sleepDidStopMenuButton {
    self.inBedStop = [NSDate date];
    self.sleepStop = [NSDate date];
    self.isSleeping = NO;
    NSLog(@"[VERBOSE] User exited in bed at %@ and woke at %@", self.inBedStop, self.sleepStop);
    
    [self.mainLabel setText:@"Press To Sleep"];
    
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    
    [self writeSleepStopDataToPlist];
    [self writeToHealthKit];
    NSLog(@"[VERBOSE] Writing data to Health.app.");
}
- (IBAction)sleepWasCancelledByUserMenuButton {
    self.inBedStop = [NSDate date];
    self.sleepStop = [NSDate date];
    self.isSleeping = NO;
    NSLog(@"[VERBOSE] User cancelled sleep at %@", self.sleepStop);
    
    [self.mainLabel setText:@"Press To Sleep"];
    
    [self clearAllMenuItems];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"Sleep" action:@selector(sleepDidStartMenuButton)];
    
    [self writeSleepStopDataToPlist];
    NSLog(@"[VERBOSE] Sleep data will not be written to Health.app.");
}

- (IBAction)sleepWasDeferredByUserMenuButton {
    self.sleepStart = [NSDate date];
    NSLog(@"[VERBOSE] User is still awake at %@", self.sleepStart);
}

// HealthKit Methods

- (void)requestAccessToHealthKit {
    NSArray *readTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    NSArray *writeTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed attempt to request access to Health.app with error: %@", error);
        }
    }];
}

- (void)readHeartRateDataFromPreviousSleep {
#warning Need to add the ability to read heart rate data.
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
    
    NSArray *sampleArray = [NSArray arrayWithObjects:sleepSample, inBedSample, nil];
    
    
    
    [self.healthStore saveObjects:sampleArray withCompletion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed to write data to Health.app with error: %@", error);
        }
    }];
}


- (void)updateLabels {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.mainLabel setText:[dateFormatter stringFromDate:self.inBedStart]];
    NSLog(@"[VERBOSE] Labels set.");
}

@end



