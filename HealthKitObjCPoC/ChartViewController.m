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
#import "ColorConstants.h"

@interface ChartViewController ()
@property (strong, nonatomic) IBOutlet UILabel *chartLabel;
@property (strong, nonatomic) IBOutlet UIStackView *yAxisStack;
@property (strong, nonatomic) IBOutlet UIStackView *xAxisStack;
@property (strong, nonatomic) IBOutlet UIView *mainChartView;
@property SleepStatistic *minStatistic;
@property SleepStatistic *maxStatistic;
@property SleepStatistic *avgStatistic;
@property SleepStatistic *sleepDuration;
@property SleepSession *detailSleepSession;
@property double yAxisPadding;
@property UIBezierPath *pathHeartRate;
@property CGPoint chartOrigin;
@property NSNumber *chartMax;
@property NSNumber *chartMin;
@property NSArray *ktimes12HourWithAMPM;
@property NSArray *ktimes12Hour;
@property NSMutableArray *heartRateMilestones;
@end

@implementation ChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPropertyDefaults];
    [self refreshHealthStatistics];
    [self drawChartSeperatorLines];
#warning remove this
//    [self highlightChartArea];
//    [self drawTicks];
}

- (void)setPropertyDefaults {
    self.view.backgroundColor = [ColorConstants darkThemeSecondaryBackgroundColor];
    _yAxisPadding = 10;
    
    [_chartLabel setText:_chartTitle];
    [_chartLabel setTextColor:[ColorConstants darkThemePrimaryTextColor]];
    
    _chartOrigin = CGPointMake(45, 36);
    _heartRateMilestones = [[NSMutableArray alloc] init];
    _detailSleepSession = [Utility convertManagedObjectSessionToSleepSessionForDetailView:_sleepSession];
    _ktimes12HourWithAMPM = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM", @"9 AM", @"10 AM", @"11 AM", @"12 PM", @"1 PM", @"2 PM", @"3 PM", @"4 PM", @"5 PM", @"6 PM", @"7 PM", @"8 PM", @"9 PM", @"10 PM", @"11 PM"];
    _ktimes12Hour = @[@"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)drawChartSeperatorLines {
    NSArray *seperatorLocations = @[@35, @240];
    
    UIView *verticalLine=[[UIView alloc]initWithFrame:CGRectMake(45, 35, 1, 205)];
    [verticalLine setBackgroundColor:[ColorConstants darkThemeLineSeperator]];
    [self.view addSubview:verticalLine];
    
    for(int i = 0; i < seperatorLocations.count; i++) {
        double yLocation = [[seperatorLocations objectAtIndex:i] floatValue];
        UIView *horizontalLine=[[UIView alloc]initWithFrame:CGRectMake(0, yLocation, self.view.bounds.size.width*2, 1)];
        [horizontalLine setBackgroundColor:[ColorConstants darkThemeLineSeperator]];
        [self.view addSubview:horizontalLine];
    }
}

- (void)highlightChartArea {
    UIView *shadedArea = [[UIView alloc]initWithFrame:CGRectMake(_mainChartView.frame.origin.x, _mainChartView.frame.origin.y + _yAxisPadding, _mainChartView.frame.size.width, _mainChartView.frame.size.height - (_yAxisPadding * 2))];
    shadedArea.backgroundColor = [UIColor redColor];
    [self.view addSubview:shadedArea];
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
//    NSArray *xAxisLabelsFromSleepSession = @[@"11", @"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
    NSArray *xAxisLabelsFromSleepSession = [self generateXAxisLabels];
    
    NSArray *yAxisLabelsFromSleepSession = [self getYAxisScale];
    
    for (int x = 0; x < xAxisLabelsFromSleepSession.count; x++) {
        UILabel *xAxisLabel = [[UILabel alloc] init];
        [xAxisLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        [xAxisLabel setTextColor:[ColorConstants darkThemePrimaryTextColor]];
        [xAxisLabel setText:xAxisLabelsFromSleepSession[x]];
        [_xAxisStack addArrangedSubview:xAxisLabel];
    }
    
    for (int x = 0; x < yAxisLabelsFromSleepSession.count; x++) {
        NSNumber *number = [yAxisLabelsFromSleepSession objectAtIndex:x];
        double valueToDisplay = [number doubleValue];
        UILabel *yAxisLabel = [[UILabel alloc] init];
        [yAxisLabel setFont:[UIFont systemFontOfSize:10]];
        [yAxisLabel setTextColor:[ColorConstants darkThemePrimaryTextColor]];
        [yAxisLabel setText:[NSString stringWithFormat:@"%.0f", valueToDisplay]];
        [_yAxisStack addArrangedSubview:yAxisLabel];
    }
    
    [self drawGridLinesForXAxis:xAxisLabelsFromSleepSession andYAxis:yAxisLabelsFromSleepSession];
}

- (NSArray*)generateXAxisLabels {
    NSDateComponents *fullSleepSessionDurationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.outBed lastObject] options:0];
    NSInteger durationHours = [fullSleepSessionDurationComponents hour];
    NSInteger durationMinutes = [fullSleepSessionDurationComponents minute];
    
    NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[_detailSleepSession.inBed firstObject]];
    NSInteger startHour = [startComponents hour];
    NSMutableArray *timeMilestones = [[NSMutableArray alloc] init];
    
    int x = 0;
    
    // Allows chart to display label for the last hour of sleep in chart
    if (durationMinutes > 0) {
        durationHours = durationHours + 1;
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
            [self drawLine];
            [self drawAverageHeartRateLine];
        }];
    }];
}

-(void)generateYAxisLabels:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    NSNumberFormatter *numberFormatterDown = [[NSNumberFormatter alloc] init];
    [numberFormatterDown setRoundingMode:NSNumberFormatterRoundDown];
    [numberFormatterDown setRoundingIncrement:[NSNumber numberWithInteger:5]];
    
    NSNumberFormatter *numberFormatterUp = [[NSNumberFormatter alloc] init];
    [numberFormatterUp setRoundingMode:NSNumberFormatterRoundUp];
    [numberFormatterUp setRoundingIncrement:[NSNumber numberWithInteger:5]];
    
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
    double chartFrameWidth = self.view.frame.size.width - 45;
    double chartFrameHeight = _mainChartView.frame.size.height - (2 * _yAxisPadding);
    int dataPointRadius = 2;
    double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
    
    // Line
    _pathHeartRate = [UIBezierPath bezierPath];
    
    // Calculate Total Time Asleep
    NSDateComponents *totalSessionDurationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.outBed lastObject] options:0];
    NSInteger hours = [totalSessionDurationComponents hour];
    NSInteger minutes = [totalSessionDurationComponents minute];
    NSInteger seconds = [totalSessionDurationComponents second];
    
    double totalSleepDuration = (hours * 3600) + (minutes * 60) + seconds;
    
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
                double yCoordinate = ((adjustedRate * chartFrameHeight) / heartRateRange) + _yAxisPadding;
                
                UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(xCoordinate + 45 - dataPointRadius, _chartOrigin.y + yCoordinate - dataPointRadius, dataPointRadius * 2, dataPointRadius * 2)];
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
                    [_pathHeartRate addLineToPoint:CGPointMake(xCoordinate, yCoordinate)];
                } else {
                    [_pathHeartRate moveToPoint:CGPointMake(xCoordinate, yCoordinate)];
                    
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
    
    // Calculates the space between the top and bottom labels of the Y-Axis
    double chartPlotableSpace = _mainChartView.frame.size.height - (_yAxisPadding * 2);
    NSLog(@"[DEBUG] chartPlotableSpace = %f", chartPlotableSpace);
    int dataPointRadius = 2;
    
    if (_avgStatistic.result) {
        
        // heartRateRange will be used in conversion function
        double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
        NSLog(@"[DEBUG] %f(max) - %f(min) = %f(heartRateRange)", _chartMax.doubleValue, _chartMin.doubleValue, heartRateRange);
        
        // adjustedRate stores the value for the difference between the top of the heartRateRange and the average
        double adjustedRate = _chartMax.doubleValue - floorf(_avgStatistic.result);
        NSLog(@"[DEBUG] %f(max) - %f(floor) = %f(adjustedRate)", _chartMax.doubleValue, floorf(_avgStatistic.result), adjustedRate);
        NSLog(@"[DEBUG] _avgStatistic.result = %f", _avgStatistic.result);
#warning Floor rounds the average down, but how do we get average for displaying statistics list view.
        
        // Converts the average heart rate to points for used in plotting on the chart. The points will represent the bottom of the chart to where the line should be plotted.
        double convertHeartRateToPoints = ((adjustedRate * chartPlotableSpace) / heartRateRange);
        NSLog(@"[DEBUG] convertHeartRateToPoints = %f", convertHeartRateToPoints);
        
        // Becuase the chart will draw from the origin, which is at the top, we will reverse the convertHeartRateToPoints to determine where it should be plotted.
        double yCoordinate = chartPlotableSpace - convertHeartRateToPoints;
        NSLog(@"[DEBUG] yCoordinate = %f", yCoordinate);
        UIView *horizontalLine = [[UIView alloc]initWithFrame:CGRectMake(_mainChartView.frame.origin.x, yCoordinate + (dataPointRadius / 2), self.view.bounds.size.width*2, 1)];
        [horizontalLine setBackgroundColor:[ColorConstants darkThemePrimaryAccentColor]];
        [self.view addSubview:horizontalLine];
        NSLog(@"%@", NSStringFromCGPoint(_mainChartView.frame.origin));
        UIView *testLine = [[UIView alloc]initWithFrame:CGRectMake(0, yCoordinate, self.view.bounds.size.width*2, 1)];
        [testLine setBackgroundColor:[ColorConstants darkThemePrimaryTextColor]];
        [_mainChartView addSubview:testLine];
    }
}

-(void)drawTicks {
    double tick = 0;
    for (int x; x<12; x++) {
        UIView *horizontalLine = [[UIView alloc]initWithFrame:CGRectMake(_mainChartView.frame.origin.x, _mainChartView.frame.origin.y + _yAxisPadding + tick, self.view.bounds.size.width, 1)];
        [horizontalLine setBackgroundColor:[UIColor redColor]];
        [self.view addSubview:horizontalLine];
        tick = tick + 18.5;
    }
}

-(void)drawLine {
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = CGRectMake(_chartOrigin.x, _chartOrigin.y, self.view.frame.size.width, self.view.frame.size.height);
    pathLayer.bounds = self.view.frame;
    pathLayer.path = _pathHeartRate.CGPath;
    pathLayer.strokeColor = [UIColor whiteColor].CGColor;
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = 1;
    pathLayer.lineJoin = kCALineJoinRound;
    [self.view.layer addSublayer:pathLayer];
}

-(void)drawGridLinesForXAxis:(NSArray*)xAxisData andYAxis:(NSArray*)yAxisData {
    if (xAxisData.count > 1 && yAxisData.count > 1) {
        double verticalGridLineSpacing = (_mainChartView.frame.size.width - 5) / (xAxisData.count - 1);
        double horizontalGridLineSpacing = (_mainChartView.frame.size.height - (_yAxisPadding * 2)) / (yAxisData.count - 1);
        
        // Draw Vertical Grid Lines
        for(int i = 1; i < xAxisData.count; i++) {
            UIBezierPath *gridLine = [UIBezierPath bezierPath];
            [gridLine moveToPoint:CGPointMake(0 + (i * verticalGridLineSpacing), 0)];
            [gridLine addLineToPoint:CGPointMake(0 + (i * verticalGridLineSpacing), 0 + _mainChartView.frame.size.height)];
            
            CAShapeLayer *gridLineLayer = [CAShapeLayer layer];
            gridLineLayer.frame = CGRectMake(0, 0, _mainChartView.frame.size.width, _mainChartView.frame.size.height);
            gridLineLayer.path = gridLine.CGPath;
            gridLineLayer.strokeColor = [ColorConstants darkThemeChartGridLineColor].CGColor;
            gridLineLayer.lineDashPattern = @[@2, @8];
            gridLineLayer.fillColor = nil;
            gridLineLayer.lineWidth = 1;
            gridLineLayer.lineJoin = kCALineJoinRound;
            [_mainChartView.layer addSublayer:gridLineLayer];
        }
        
        // Draw Horizontal Grid Lines
        for (int i = 0; i < yAxisData.count; i++) {
            UIBezierPath *gridLine = [UIBezierPath bezierPath];
            if (i == 0) {
                [gridLine moveToPoint:CGPointMake(0, _yAxisPadding)];
                [gridLine addLineToPoint:CGPointMake(_mainChartView.frame.size.width + 5, _yAxisPadding)];
            } else if (i == yAxisData.count - 1) {
                [gridLine moveToPoint:CGPointMake(0, _mainChartView.frame.size.height - _yAxisPadding)];
                [gridLine addLineToPoint:CGPointMake(_mainChartView.frame.size.width + 5, _mainChartView.frame.size.height - _yAxisPadding)];
            } else {
                [gridLine moveToPoint:CGPointMake(0, _yAxisPadding + (horizontalGridLineSpacing * i))];
                [gridLine addLineToPoint:CGPointMake(_mainChartView.frame.size.width + 5, _yAxisPadding + (horizontalGridLineSpacing * i))];
            }
            CAShapeLayer *gridLineLayer = [CAShapeLayer layer];
            gridLineLayer.frame = CGRectMake(0, 0, _mainChartView.frame.size.width + 5, 0 + (horizontalGridLineSpacing * i));
            gridLineLayer.path = gridLine.CGPath;
            gridLineLayer.strokeColor = [ColorConstants darkThemeChartGridLineColor].CGColor;
            gridLineLayer.lineDashPattern = @[@2, @8];
            gridLineLayer.fillColor = nil;
            gridLineLayer.lineWidth = 1;
            gridLineLayer.lineJoin = kCALineJoinRound;
            [_mainChartView.layer addSublayer:gridLineLayer];
            
        }
    } else {
        NSLog(@"[DEBUG] No Data To Draw");
    }
}

-(NSArray *)getYAxisScale {
    double yAxisRange = [_chartMax doubleValue] - [_chartMin doubleValue];
    double scaleBy = 0;
    double valueToSet = [_chartMin doubleValue];
    NSMutableArray *yAxisLabelsToDisplay = [[NSMutableArray alloc] init];
    if (yAxisRange <= 20) {
        scaleBy = 5;
    } else if (yAxisRange <= 40) {
        scaleBy = 10;
    } else if (yAxisRange <= 60) {
        scaleBy = 20;
    } else {
        scaleBy = 25;
    }
    
    while (valueToSet < [_chartMax doubleValue]) {
        valueToSet = valueToSet + scaleBy;
        NSNumber *yAxisDataPoint = [[NSNumber alloc] initWithDouble:valueToSet];
        [yAxisLabelsToDisplay addObject:yAxisDataPoint];
    }
    [yAxisLabelsToDisplay insertObject:_chartMin atIndex:0];
    NSArray *reversedArray = [[yAxisLabelsToDisplay reverseObjectEnumerator] allObjects];
    _chartMax = [reversedArray firstObject];
    
    return reversedArray;
}

@end
