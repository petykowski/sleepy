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
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    self.isSleeping = [self isSleepinProgress];
    
    NSLog(@"[DEBUG] Sleep staus at init = %d", self.isSleeping);
    
    // If sleep is currently in progress update our labels.
    if (self.isSleeping) {
        [self sleepInProgressWillReadDataFromPlist];
//        [self.mainLabel setText:@"Sleeping"];
    }
    
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

}

- (void)willActivate {
    [super willActivate];
    
    NSLog(@"[DEBUG] Sleep staus at Activate = %d", self.isSleeping);

    HKAuthorizationStatus hasAccessToSleepData = [self.healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    if (hasAccessToSleepData == 0) {
        NSLog(@"[DEBUG] No Access, request access to services.");
        [self requestAccessToHealthKit];
    }
    
}

- (void)didDeactivate {
    [super didDeactivate];
    
    if (self.isSleeping) {
#warning Need to write dates to plist.
    }
    
}

// Plist Methods

- (BOOL)isSleepinProgress {
    
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Health.plist"];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSNumber *sleeping = [plistDictionary objectForKey:@"SleepInProgress"];
    BOOL thebool = [sleeping boolValue];
    return thebool;
}

- (void)sleepInProgressWillReadDataFromPlist {
    
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Health.plist"];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    self.inBedStart = [plistDictionary objectForKey:@"StartInBedDate"];
    self.sleepStart = [plistDictionary objectForKey:@"StartSleepDate"];
    [self updateLabels];
    NSLog(@"[DEBUG] in bed = %@", self.inBedStart);
    NSLog(@"[DEBUG] sleep = %@", self.sleepStart);
}

- (void)writeSleepStartDataToPlist {
    
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSNumber *sleeping = [[NSNumber alloc] initWithBool:self.isSleeping];
    [plistDictionary setObject:sleeping forKey:@"SleepInProgress"];
    [plistDictionary setObject:self.inBedStart forKey:@"StartInBedDate"];
    [plistDictionary setObject:self.sleepStart forKey:@"StartSleepDate"];
    
    [plistDictionary writeToFile:plistPath atomically:YES];
}

- (void)writeSleepStopDataToPlist {
    
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Health.plist"];
    NSMutableDictionary *plistDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSNumber *sleeping = [[NSNumber alloc] initWithBool:self.isSleeping];
    [plistDictionary setObject:sleeping forKey:@"SleepInProgress"];
    [plistDictionary setObject:[NSDate date] forKey:@"StartInBedDate"];
    [plistDictionary setObject:[NSDate date] forKey:@"StartSleepDate"];
    
    [plistDictionary writeToFile:plistPath atomically:YES];
}

// Button Methods

- (IBAction)sleepDidStartButton {
    self.inBedStart = [NSDate date];
    self.sleepStart = [NSDate date];
    self.isSleeping = YES;
    [self updateLabels];
    [self writeSleepStartDataToPlist];
}

- (IBAction)sleepDidStopButton {
    self.inBedStop = [NSDate date];
    self.sleepStop = [NSDate date];
    self.isSleeping = NO;
    
    [self.mainLabel setText:@""];
    [self writeSleepStopDataToPlist];
    [self writeToHealthKit];
    
}


// HealthKit Methods

- (void)requestAccessToHealthKit {
    NSArray *readTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    NSArray *writeTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed with error: %@", error);
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
            NSLog(@"[DEBUG] Failed to write data with error: %@", error);
        }
    }];
}


- (void)updateLabels {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.mainLabel setText:[dateFormatter stringFromDate:self.inBedStart]];
}

@end



