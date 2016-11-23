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
@property SleepStatistic *minStatistic;
@property SleepStatistic *maxStatistic;
@property SleepStatistic *avgStatistic;
@property SleepStatistic *sleepDuration;
@property SleepSession *detailSleepSession;
@property UIBezierPath *path;
@property NSNumber *chartMax;
@property NSNumber *chartMin;
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
    [self drawChartSeperatorLines];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)drawChartSeperatorLines {
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
//    int indexCount = 0;
//    int maxNumberOfLabels = 6;
//    NSArray *xAxisLabelsFromSleepSession = [self generateXAxisLabels];
//    NSMutableArray *xAxisLabelsToDisplay = [[NSMutableArray alloc] init];
    
//    xAxisLabelsFromSleepSession = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM"];
    
//    if (xAxisLabelsFromSleepSession.count < maxNumberOfLabels) {
//        
//        maxNumberOfLabels = (int)xAxisLabelsFromSleepSession.count;
//        [xAxisLabelsToDisplay addObjectsFromArray:xAxisLabelsFromSleepSession];
//        
//    } else if (xAxisLabelsFromSleepSession.count <= 11) {
//        
//        while (xAxisLabelsToDisplay.count <= 6 && indexCount <= xAxisLabelsFromSleepSession.count) {
//            [xAxisLabelsToDisplay addObject:xAxisLabelsFromSleepSession[indexCount]];
//            indexCount += 2;
//        };
//    } else if (xAxisLabelsFromSleepSession.count > 11) {
//        
//        for (int x = 0; x < maxNumberOfLabels; x++) {
//            if (x == 0) {
//                [xAxisLabelsToDisplay addObject:[xAxisLabelsFromSleepSession firstObject]];
//            } else if (x == maxNumberOfLabels -1) {
//                [xAxisLabelsToDisplay addObject:[xAxisLabelsFromSleepSession lastObject]];
//            } else {
//                indexCount += 2;
//                [xAxisLabelsToDisplay addObject:xAxisLabelsFromSleepSession[indexCount]];
//            }
//        }
//    }
//    
//    for (int x = 0; x < xAxisLabelsToDisplay.count; x++) {
//        UILabel *xAxisLabel = [[UILabel alloc] init];
//        [xAxisLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
//        [xAxisLabel setTextColor:[UIColor whiteColor]];
//        [xAxisLabel setText:xAxisLabelsToDisplay[x]];
//        [_xAxisStack addArrangedSubview:xAxisLabel];
//    }
    
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
    if (durationHours % 2) {
        // durationHours is odd... do nothing
    } else if (durationHours > 6) {
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
    
    return [HKQuery predicateForSamplesWithStartDate:[_detailSleepSession.inBed firstObject] endDate:[_detailSleepSession.outBed lastObject] options:HKQueryOptionNone];
}

- (void)refreshHealthStatistics {
    [self generateYAxisLabels:^(NSError *error) {
        [self plotHeartRateOnGraph:^(NSError *error){
            [self updateAxisLabels];
            [self drawAverageHeartRateLine];
            [self drawLine];
        }];
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
                    
                    _minStatistic = [[SleepStatistic alloc] initWithDouble:[result.minimumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
                    _maxStatistic = [[SleepStatistic alloc] initWithDouble:[result.maximumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
                    _avgStatistic = [[SleepStatistic alloc] initWithDouble:[result.averageQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
            
                    _minStatistic.stringResult = [NSString stringWithFormat:@"%@ bpm", [numberFormatterDown stringFromNumber:[NSNumber numberWithFloat:_minStatistic.result]]];
                    _maxStatistic.stringResult = [NSString stringWithFormat:@"%@ bpm", [numberFormatterUp stringFromNumber:[NSNumber numberWithFloat:_maxStatistic.result]]];
                    _avgStatistic.stringResult = [NSString stringWithFormat:@"%@ bpm", [numberFormatterUp stringFromNumber:[NSNumber numberWithFloat:_avgStatistic.result]]];
                    
                    NSString *min = [NSString stringWithFormat:@"%@", [numberFormatterDown stringFromNumber:[NSNumber numberWithFloat:_minStatistic.result]]];
                    NSString *max = [NSString stringWithFormat:@"%@", [numberFormatterUp stringFromNumber:[NSNumber numberWithFloat:_maxStatistic.result]]];
                    
                    _chartMin = [numberFormatterDown numberFromString:min];
                    _chartMax = [numberFormatterUp numberFromString:max];
                    
                    [_heartRateMilestones addObject:_maxStatistic];
                    [_heartRateMilestones addObject:_minStatistic];
                }
                if (completionHandler) {
                    completionHandler(error);
                }
            });
        }];
        
    [self.healthStore executeQuery:maxHeartRateQuery];
}

-(void) plotHeartRateOnGraph:(void (^)(NSError *))completionHandler {
    // Testing
    double chartFrameWidth = self.view.frame.size.width - 45;
    double chartFrameHeight = 205;
    CGPoint chartOrigin = CGPointMake(45, 36);
    int dataPointRadius = 2;
    double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
    
    // Line
    _path = [UIBezierPath bezierPath];
    
    
    // Calculate Total Time Asleep
    NSDateComponents *totalSessionDurationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.outBed lastObject] options:0];
    NSInteger hours = [totalSessionDurationComponents hour];
    NSInteger minutes = [totalSessionDurationComponents minute];
    NSInteger seconds = [totalSessionDurationComponents second];
    
    double totalSleepDuration = (hours * 3600) + (minutes * 60) + seconds;
    // End Testing
    
    NSDate *sampleStartDate = [_detailSleepSession.inBed firstObject];
    NSDate *sampleEndDate = [_detailSleepSession.outBed lastObject];
    
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:sampleStartDate endDate:sampleEndDate options:HKQueryOptionNone];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (!results) {
            NSLog(@"An error has occured. The error was: %@", error);
            abort();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            int indexCount = 0;
            for (HKQuantitySample *sample in results) {
                NSDateComponents *durationToReading = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[_detailSleepSession.inBed firstObject] toDate:sample.startDate options:0];
                NSInteger sampleHours = [durationToReading hour];
                NSInteger sampleminutes = [durationToReading minute];
                NSInteger sampleseconds = [durationToReading second];
                
                // Calculate X Coordinate
                double sampleDuration = (sampleHours * 3600) + (sampleminutes * 60) + sampleseconds;
                double xCoordinate = (sampleDuration * chartFrameWidth) / totalSleepDuration;
                
                // Calculate Y Coordinate
                double heartRate = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
                double adjustedRate = _chartMax.doubleValue - heartRate;
                double yCoordinate = (adjustedRate * chartFrameHeight) / heartRateRange;
                
                UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(xCoordinate + 45 - dataPointRadius, chartOrigin.y + yCoordinate - dataPointRadius, dataPointRadius * 2, dataPointRadius * 2)];
                CAShapeLayer *fillLayer = [CAShapeLayer layer];
                fillLayer.frame = CGRectMake(xCoordinate + 45, 100, dataPointRadius, dataPointRadius);
                fillLayer.bounds = CGRectMake(xCoordinate + 45, 100, dataPointRadius, dataPointRadius);
                fillLayer.path = circle.CGPath;
                fillLayer.strokeColor = [UIColor whiteColor].CGColor;
                fillLayer.fillColor = [UIColor whiteColor].CGColor;
                fillLayer.lineWidth = 1;
                fillLayer.lineJoin = kCALineJoinRound;
                [self.view.layer addSublayer:fillLayer];
                
                if (indexCount > 0) {
                    [_path addLineToPoint:CGPointMake(xCoordinate, yCoordinate)];
                } else {
                    [_path moveToPoint:CGPointMake(xCoordinate, yCoordinate)];
                    
                }
                indexCount = indexCount + 1;
            }
            if (completionHandler) {
                completionHandler(error);
            }
        });
    }];
    [self.healthStore executeQuery:query];
}

-(void)drawAverageHeartRateLine {
    CGPoint chartOrigin = CGPointMake(45, 36);
    double chartFrameHeight = 205;
    if (_avgStatistic.result) {
        double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
        double adjustedRate = _chartMax.doubleValue - _avgStatistic.result;
        double yCoordinate = (adjustedRate * chartFrameHeight) / heartRateRange;
        UIView *horizontalLine = [[UIView alloc]initWithFrame:CGRectMake(45, chartOrigin.y + yCoordinate, self.view.bounds.size.width*2, 1)];
        [horizontalLine setBackgroundColor:[UIColor colorWithRed:0.3725490196 green:0.3058823529 blue:0.7176470588 alpha:1]];
        [self.view addSubview:horizontalLine];
    }
}

-(void)drawLine {
    CGPoint chartOrigin = CGPointMake(45, 36);
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = CGRectMake(chartOrigin.x, chartOrigin.y, self.view.frame.size.width, self.view.frame.size.height);
    pathLayer.bounds = self.view.frame;
    pathLayer.path = _path.CGPath;
    pathLayer.strokeColor = [UIColor whiteColor].CGColor;
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = 1;
    pathLayer.lineJoin = kCALineJoinRound;
    [self.view.layer addSublayer:pathLayer];
}

@end
