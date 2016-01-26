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

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mainLabel;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

}

- (void)willActivate {
    [super willActivate];
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    HKAuthorizationStatus hasAccessToSleepData = [self.healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]];
    
    if (hasAccessToSleepData == 0) {
        NSLog(@"[DEBUG] No Access, request access to services.");
        [self requestAccessToHealthKit];
    }
    
}

- (void)didDeactivate {
    [super didDeactivate];
}


// Button Methods

- (IBAction)sleepDidStartButton {
    self.inBedStart = [NSDate dateWithTimeInterval:-60*60*8 sinceDate:[NSDate date]];
    self.sleepStart = [NSDate dateWithTimeInterval:60*15 sinceDate:self.inBedStart];
    [self updateLabels];
}

- (IBAction)sleepDidStopButton {
    self.inBedStop = [NSDate date];
    self.sleepStop = [NSDate dateWithTimeInterval:-60*15 sinceDate:self.inBedStop];
    [self.mainLabel setText:@""];
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

//- (void)readHeartRateDataFromPreviousSleep {
//    HKQuery *heartRateData = [[HKQuery alloc] init];
//    [self.healthStore executeQuery:heartRateData];
//    
//}

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



