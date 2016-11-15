//
//  ChartViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 11/13/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "ChartViewController.h"
#import <HealthKit/HealthKit.h>
#import "SleepSession.h"
#import "SleepStatistic.h"
#import "Utility.h"

@interface ChartViewController ()
@property (strong, nonatomic) IBOutlet UILabel *chartLabel;
@property (strong, nonatomic) IBOutlet UIStackView *yAxisStack;
@property (strong, nonatomic) IBOutlet UIStackView *xAxisStack;
@property SleepSession *detailSleepSession;
@property NSArray *ktimes12Hour;
@property NSMutableArray *heartRateMilestones;

@end

@implementation ChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _heartRateMilestones = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.1137254902 green:0.1137254902 blue:0.1137254902 alpha:1.0];
    _detailSleepSession = [Utility convertManagedObjectSessionToSleepSessionForDetailView:_sleepSession];
    _ktimes12Hour = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM", @"9 AM", @"10 AM", @"11 AM", @"12 PM", @"1 PM", @"2 PM", @"3 PM", @"4 PM", @"5 PM", @"6 PM", @"7 PM", @"8 PM", @"9 PM", @"10 PM", @"11 PM"];
    
    [_chartLabel setText:_chartTitle];
    [_chartLabel setTextColor:[UIColor whiteColor]];
    [self refreshHealthStatistics];
    [self drawSeperatorLines];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)drawSeperatorLines {
    NSArray *seperatorLocations = @[@35, @240];
    
    UIView *verticalLine=[[UIView alloc]initWithFrame:CGRectMake(45, 35, 1, 205)];
    [verticalLine setBackgroundColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2078431373 alpha:1.0]];
    [self.view addSubview:verticalLine];
    
    for(int i = 0; i < seperatorLocations.count; i++) {
        double yLocation = [[seperatorLocations objectAtIndex:i] floatValue];
        UIView *horizontalLine=[[UIView alloc]initWithFrame:CGRectMake(0, yLocation, self.view.bounds.size.width*2, 1)];
        [horizontalLine setBackgroundColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2078431373 alpha:1.0]];
        [self.view addSubview:horizontalLine];
    }
}

- (void)updateAxisLabels {
    int indexCount = 0;
    int maxNumberOfLabels = 6;
    NSArray *xAxisLabelsFromSleepSession = [self generateXAxisLabels];
    NSMutableArray *xAxisLabelsToDisplay = [[NSMutableArray alloc] init];
    
//    xAxisLabelsFromSleepSession = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM"];
    
    if (xAxisLabelsFromSleepSession.count < maxNumberOfLabels) {
        
        maxNumberOfLabels = (int)xAxisLabelsFromSleepSession.count;
        [xAxisLabelsToDisplay addObjectsFromArray:xAxisLabelsFromSleepSession];
        
    } else if (xAxisLabelsFromSleepSession.count <= 11) {
        
        while (xAxisLabelsToDisplay.count <= 6 && indexCount <= xAxisLabelsFromSleepSession.count) {
            [xAxisLabelsToDisplay addObject:xAxisLabelsFromSleepSession[indexCount]];
            indexCount += 2;
        };
    } else if (xAxisLabelsFromSleepSession.count > 11) {
        
        for (int x = 0; x < maxNumberOfLabels; x++) {
            if (x == 0) {
                [xAxisLabelsToDisplay addObject:[xAxisLabelsFromSleepSession firstObject]];
            } else if (x == maxNumberOfLabels -1) {
                [xAxisLabelsToDisplay addObject:[xAxisLabelsFromSleepSession lastObject]];
            } else {
                indexCount += 2;
                [xAxisLabelsToDisplay addObject:xAxisLabelsFromSleepSession[indexCount]];
            }
        }
    }
    
    for (int x = 0; x < xAxisLabelsToDisplay.count; x++) {
        UILabel *xAxisLabel = [[UILabel alloc] init];
        [xAxisLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        [xAxisLabel setTextColor:[UIColor whiteColor]];
        [xAxisLabel setText:xAxisLabelsToDisplay[x]];
        [_xAxisStack addArrangedSubview:xAxisLabel];
    }
    
    for (int x = 0; x < _heartRateMilestones.count; x++) {
        UILabel *yAxisLabel = [[UILabel alloc] init];
        [yAxisLabel setFont:[UIFont systemFontOfSize:10]];
        [yAxisLabel setTextColor:[UIColor whiteColor]];
        SleepStatistic *stat = [_heartRateMilestones objectAtIndex:x];
        [yAxisLabel setText:stat.stringResult];
        [_yAxisStack addArrangedSubview:yAxisLabel];
    }
    
}

- (NSArray*)generateXAxisLabels {
    NSDateComponents *durationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.outBed lastObject] options:0];
    NSInteger durationHours = [durationComponents hour];
    NSInteger durationMinutes = [durationComponents minute];
    
    NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[_detailSleepSession.sleep firstObject]];
    NSInteger startHour = [startComponents hour];
    
    NSMutableArray *timeMilestones = [[NSMutableArray alloc] init];
    
    int x = 0;
    
    // Allows chart to display label for the last hour of sleep in chart
    if (durationMinutes > 0) {
        durationHours = durationHours + 1;
    }
    
    // Makes the Array count odd to allow for displaying every other item
    if (durationHours % 2 && durationHours > 6) {
        durationHours++;
    }
    
    while (x <= durationHours) {
        if (startHour > _ktimes12Hour.count - 1) {
            startHour = startHour - [_ktimes12Hour count];
        }
        [timeMilestones addObject:_ktimes12Hour[startHour]];
        startHour++;
        x++;
    }
    
    return timeMilestones;
}

- (NSPredicate *)predicateForSleepDuration {
    
    return [HKQuery predicateForSamplesWithStartDate:[_detailSleepSession.sleep firstObject] endDate:[_detailSleepSession.wake lastObject] options:HKQueryOptionNone];
}

- (void)refreshHealthStatistics {
    [self generateYAxisLabels:^(NSError *error) {
        [self updateAxisLabels];
    }];
}

-(void)generateYAxisLabels:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    NSNumberFormatter *numberFormatterDown = [[NSNumberFormatter alloc] init];
    [numberFormatterDown setRoundingMode:NSNumberFormatterRoundDown];
    [numberFormatterDown setRoundingIncrement:[NSNumber numberWithInteger:10]];
    
    NSNumberFormatter *numberFormatterUp = [[NSNumberFormatter alloc] init];
    [numberFormatterUp setRoundingMode:NSNumberFormatterRoundUp];
    [numberFormatterUp setRoundingIncrement:[NSNumber numberWithInteger:10]];
    
        HKStatisticsQuery *maxHeartRateQuery = [[HKStatisticsQuery alloc] initWithQuantityType:heartRateQuantityType quantitySamplePredicate:predicate options:HKStatisticsOptionDiscreteMax | HKStatisticsOptionDiscreteMin | HKStatisticsOptionDiscreteAverage completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (result) {
                    
                    SleepStatistic *minStatistic = [[SleepStatistic alloc] init];
                    SleepStatistic *maxStatistic = [[SleepStatistic alloc] init];
                    
                    minStatistic.result = [result.minimumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
                    maxStatistic.result = [result.maximumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
            
                    minStatistic.stringResult = [NSString stringWithFormat:@"%@ bpm", [numberFormatterDown stringFromNumber:[NSNumber numberWithFloat:minStatistic.result]]];
                    maxStatistic.stringResult = [NSString stringWithFormat:@"%@ bpm", [numberFormatterUp stringFromNumber:[NSNumber numberWithFloat:maxStatistic.result]]];
                    
                    [_heartRateMilestones addObject:maxStatistic];
                    [_heartRateMilestones addObject:minStatistic];
                }
                if (completionHandler) {
                    completionHandler(error);
                }
            });
        }];
        
    [self.healthStore executeQuery:maxHeartRateQuery];
}

@end
