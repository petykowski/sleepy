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
#import "Constants.h"

@interface ChartViewController ()
@property (strong, nonatomic) IBOutlet UILabel *chartLabel;
@property (strong, nonatomic) IBOutlet UIStackView *yAxisStack;
@property (strong, nonatomic) IBOutlet UIStackView *xAxisStack;
@property (strong, nonatomic) IBOutlet UIView *mainChartView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *xAxisLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *xAxisTrailingConstraint;
@property UIView *plottedPoints;
@property SleepStatistic *minStatistic;
@property SleepStatistic *maxStatistic;
@property SleepStatistic *avgStatistic;
@property SleepStatistic *sleepDuration;
@property SleepSession *detailSleepSession;
@property double xAxisPadding;
@property double yAxisPadding;
@property double verticalGridLinePadding;
@property UIBezierPath *pathHeartRate;
@property CGPoint chartOrigin;
@property NSNumber *chartMax;
@property NSNumber *chartMin;
@property NSNumber *heartRateMax;
@property NSNumber *heartRateMin;
@property NSArray *ktimes12HourWithAMPM;
@property NSArray *ktimes12Hour;
@property NSMutableArray *heartRateMilestones;
@property NSMutableArray *xAxisValues;
@property NSMutableArray *yAxisValues;
@property double xAxisLeadingShift;
@property double xAxisTrailingShift;
@property bool kNoHRDataToDisplay;
@end

@implementation ChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPropertyDefaults];
    [self getHeartRateDataFromHealthKit:^(NSError *error) {
        if (error) {
            // No data avilable or disallowed from HealthKit or error
            NSLog(@"An error has occured. The error was: %@", error);
            [self blurChartAndDisplayNoDataMessage];
        } else {
            [self getChartProperties];
            [self drawChart];
        }
    }];
}

#pragma mark - Chart Defaults

- (void)setPropertyDefaults {
    self.view.backgroundColor = [ColorConstants darkThemeSecondaryBackgroundColor];
    _xAxisPadding = 10;
    _yAxisPadding = 10;
    _verticalGridLinePadding = 6;
    
    [_chartLabel setText:_chartTitle];
    [_chartLabel setTextColor:[ColorConstants darkThemePrimaryTextColor]];
    
    _chartOrigin = CGPointMake(45, 36);
    _heartRateMilestones = [[NSMutableArray alloc] init];
    _detailSleepSession = [Utility convertManagedObjectSessionToSleepSessionForDetailView:_sleepSession];
    _ktimes12HourWithAMPM = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM", @"9 AM", @"10 AM", @"11 AM", @"12 PM", @"1 PM", @"2 PM", @"3 PM", @"4 PM", @"5 PM", @"6 PM", @"7 PM", @"8 PM", @"9 PM", @"10 PM", @"11 PM"];
    _ktimes12Hour = @[@"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11"];
}

- (void)blurChartAndDisplayNoDataMessage {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [blurEffectView setFrame:self.view.bounds];

    UILabel *titleLabel = [UILabel new];
    titleLabel.frame = blurEffectView.frame;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    titleLabel.textColor = [ColorConstants darkThemePrimaryTextColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 0;
    titleLabel.text = kNoHeartRateDataToDisplayTitle;

    [self.view addSubview:blurEffectView];
    [self.view addSubview:titleLabel];
    
}

#pragma mark - HealthKit Methods

- (NSPredicate *)predicateForSleepDuration {
    
    return [HKQuery predicateForSamplesWithStartDate:[_detailSleepSession.inBed firstObject] endDate:[_detailSleepSession.outBed lastObject] options:HKQueryOptionNone];
}

/**
 * @brief Determine the minimum (minStatistic), maximum (maxStatistic), and average (avgStatistic) statistics for the given sleep session by querying the HealthStore against the total sleep session duration.
 */
- (void)getHeartRateDataFromHealthKit:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKStatisticsQuery *maxHeartRateQuery = [[HKStatisticsQuery alloc] initWithQuantityType:heartRateQuantityType quantitySamplePredicate:predicate options:HKStatisticsOptionDiscreteMax | HKStatisticsOptionDiscreteMin | HKStatisticsOptionDiscreteAverage completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (result) {
                
                _minStatistic = [[SleepStatistic alloc] initWithDouble:[result.minimumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
                _maxStatistic = [[SleepStatistic alloc] initWithDouble:[result.maximumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
                _avgStatistic = [[SleepStatistic alloc] initWithDouble:[result.averageQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]]];
                
                _minStatistic.stringResult = [NSString stringWithFormat:@"%.0f bpm", _minStatistic.result];
                _maxStatistic.stringResult = [NSString stringWithFormat:@"%.0f bpm", _maxStatistic.result];
                _avgStatistic.stringResult = [NSString stringWithFormat:@"%.0f bpm", _avgStatistic.result];
                
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


#pragma mark - Chart Property Methods

/**
 * @brief Wrapper method to call on calculations for the x and y axis.
 */
- (void)getChartProperties {
    [self calculateXAxisValues];
    [self calculateYAxisValues];
}

- (void)calculateXAxisValues {
    NSDateComponents *sleepSessionStartComponents = [[NSCalendar currentCalendar]
                                                     components:NSCalendarUnitHour|NSCalendarUnitMinute
                                                     fromDate:[_detailSleepSession.inBed firstObject]];
    NSDateComponents *sleepSessionEndComponents = [[NSCalendar currentCalendar]
                                                   components:NSCalendarUnitHour|NSCalendarUnitMinute
                                                   fromDate:[_detailSleepSession.outBed lastObject]];
    NSInteger startHour = [sleepSessionStartComponents hour];
    NSInteger startMinute = [sleepSessionStartComponents minute];
    NSInteger endHour = [sleepSessionEndComponents hour];
    
    NSDateComponents *fullSleepSessionDurationComponents = [[NSCalendar currentCalendar]
                                                            components:NSCalendarUnitHour|NSCalendarUnitMinute
                                                            fromDate:[_detailSleepSession.inBed firstObject]
                                                            toDate:[_detailSleepSession.outBed lastObject]
                                                            options:0];
    NSInteger durationHours = [fullSleepSessionDurationComponents hour];
    NSInteger durationMinutes = [fullSleepSessionDurationComponents minute];
    NSMutableArray *timeMilestones = [[NSMutableArray alloc] init];
    
    NSLog(@"[DEBUG] startHour = %ld", (long)startHour);
    NSLog(@"[DEBUG] endHour = %ld", (long)endHour);
    NSLog(@"[DEBUG] durationHours = %ld", (long)durationHours);
    NSLog(@"[DEBUG] durationMinutes = %ld", (long)durationMinutes);
    
    int x = 0;
    
    if (startMinute + durationMinutes > 60) {
        durationHours = durationHours + 1;
    }
    
    while (x <= durationHours) {
        if (startHour == _ktimes12Hour.count) {
            startHour = startHour - 24;
        }
        
        [timeMilestones addObject:_ktimes12Hour[startHour]];
        startHour++;
        x++;
    }
    
    _xAxisValues = timeMilestones;
    NSLog(@"[DEBUG] _xAxisValues = %@", _xAxisValues);
}

- (void)calculateYAxisValues {
    if (!_yAxisValues) {
        _yAxisValues = [[NSMutableArray alloc] init];
    }
    
    NSNumberFormatter *numberFormatterDown = [[NSNumberFormatter alloc] init];
    [numberFormatterDown setRoundingMode:NSNumberFormatterRoundDown];
    [numberFormatterDown setRoundingIncrement:[NSNumber numberWithInteger:5]];
    NSString *min = [NSString stringWithFormat:@"%@", [numberFormatterDown stringFromNumber:[NSNumber numberWithFloat:_minStatistic.result]]];
    
    double yAxisRange = _maxStatistic.result - _minStatistic.result;
    double scaleByIncrement = 0;
    double chartBase = [[numberFormatterDown numberFromString:min] doubleValue];
    double yAxisValue = chartBase;
    
    NSMutableArray *yAxisLabelsToDisplay = [[NSMutableArray alloc] init];
    [yAxisLabelsToDisplay insertObject:[NSNumber numberWithFloat:chartBase] atIndex:0];
    
    if (yAxisRange <= 20) {
        scaleByIncrement = 5;
    } else if (yAxisRange <= 40) {
        scaleByIncrement = 10;
    } else if (yAxisRange <= 60) {
        scaleByIncrement = 20;
    } else {
        scaleByIncrement = 25;
    }
    
    while (yAxisValue < _maxStatistic.result) {
        yAxisValue = yAxisValue + scaleByIncrement;
        NSNumber *yAxisDataPoint = [[NSNumber alloc] initWithDouble:yAxisValue];
        [yAxisLabelsToDisplay addObject:yAxisDataPoint];
    }
    
    NSArray *reversedArray = [[yAxisLabelsToDisplay reverseObjectEnumerator] allObjects];
    
    _yAxisValues = [[NSMutableArray alloc] initWithArray:reversedArray];
    _chartMin = [reversedArray lastObject];
    _chartMax = [reversedArray firstObject];
}


#pragma mark - Chart Drawing Methods

- (void)drawChart {
    [self drawChartFrameLines];
    [self plotHeartRateOnGraph:^(NSError *error){
        if (_kNoHRDataToDisplay) {
            [self blurChartAndDisplayNoDataMessage];
        } else {
            [self strokeHeartRatePathOnChart];
            [self drawAverageHeartRateLine];
            [self shiftLabels];
            [self drawXAndYAxisLabelsGridLines];
            [self drawXAndYAxisLabels];
            [self organizeStack];
        }
    }];
}

- (void)shiftLabels {
    [self calculateXAxisLabelShift];
    _xAxisLeadingConstraint.constant = _xAxisLeadingConstraint.constant - _xAxisLeadingShift;
    _xAxisTrailingConstraint.constant = _xAxisTrailingConstraint.constant + _xAxisTrailingShift;
}

-(void) organizeStack {
    [self.view bringSubviewToFront:_yAxisStack];
    [self.view bringSubviewToFront:_plottedPoints];
}

- (void)calculateXAxisLabelShift {
    double chartFrameWidth = self.view.frame.size.width - 45;
    
    NSDateComponents *sleepSessionStartComponents = [[NSCalendar currentCalendar]
                                                     components:NSCalendarUnitMinute fromDate:[_detailSleepSession.inBed firstObject]];
    NSDateComponents *sleepSessionEndComponents = [[NSCalendar currentCalendar]
                                                   components:NSCalendarUnitMinute fromDate:[_detailSleepSession.outBed lastObject]];
    NSDateComponents *totalSessionDurationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.outBed lastObject] options:0];
    
    NSInteger startMinute = [sleepSessionStartComponents minute];
    NSInteger endMinute = [sleepSessionEndComponents minute];
    NSInteger durationHours = [totalSessionDurationComponents hour];
    NSInteger durationMinutes = [totalSessionDurationComponents minute];
    NSInteger durationSeconds = [totalSessionDurationComponents second];
    
    double totalSleepDurationInSeconds = (durationHours * 3600) + (durationMinutes * 60) + durationSeconds;
    
    _xAxisLeadingShift = (((startMinute * 60) * chartFrameWidth) / totalSleepDurationInSeconds) + 5;
    _xAxisTrailingShift = (((endMinute * 60) * chartFrameWidth) / totalSleepDurationInSeconds) - 5;
}

- (void)drawChartFrameLines {
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

- (void)drawXAndYAxisLabels {
    NSArray *xAxisLabelsFromSleepSession = _xAxisValues;
    NSArray *yAxisLabelsFromSleepSession = _yAxisValues;
    
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
}

- (void)drawXAndYAxisLabelsGridLines {
    NSMutableArray *xAxisData = _xAxisValues;
    NSMutableArray *yAxisData = _yAxisValues;
    
    if (xAxisData.count > 1 && yAxisData.count > 1) {
        double verticalGridLineSpacing = (_xAxisStack.frame.size.width + _xAxisLeadingShift - _xAxisTrailingShift - _xAxisPadding) / (_xAxisValues.count - 1);
        double horizontalGridLineSpacing = (_mainChartView.frame.size.height - (_yAxisPadding * 2)) / (yAxisData.count - 1);
        
        UIView *verticalGridLineView = [[UIView alloc] initWithFrame:CGRectMake(_mainChartView.frame.origin.x -_xAxisLeadingShift + _verticalGridLinePadding, _mainChartView.frame.origin.y, _xAxisStack.frame.size.width + _xAxisLeadingShift - _xAxisTrailingShift - _xAxisPadding, _mainChartView.frame.size.height)];
        
        // Draw Vertical Grid Lines
        for (int i = 0; i < _xAxisValues.count; i++) {
            UIBezierPath *gridLine = [UIBezierPath bezierPath];
            [gridLine moveToPoint:CGPointMake((i * verticalGridLineSpacing), 0)];
            [gridLine addLineToPoint:CGPointMake((i * verticalGridLineSpacing), 0 + _mainChartView.frame.size.height)];
            
            CAShapeLayer *gridLineLayer = [CAShapeLayer layer];
            gridLineLayer.frame = CGRectMake(0, 0, _mainChartView.frame.size.width, _mainChartView.frame.size.height);
            gridLineLayer.path = gridLine.CGPath;
            gridLineLayer.strokeColor = [ColorConstants darkThemeChartGridLineColor].CGColor;
            gridLineLayer.lineDashPattern = @[@2, @8];
            gridLineLayer.fillColor = nil;
            gridLineLayer.lineWidth = 1;
            gridLineLayer.lineJoin = kCALineJoinRound;
            [verticalGridLineView.layer addSublayer:gridLineLayer];
        }
        [self.view addSubview:verticalGridLineView];
        
        UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(0, _mainChartView.frame.origin.y + 1, 45,_mainChartView.frame.size.height - 1)];
        [cover setBackgroundColor:[ColorConstants darkThemeSecondaryBackgroundColor]];
        [self.view insertSubview:cover aboveSubview:verticalGridLineView];

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

- (void)plotHeartRateOnGraph:(void (^)(NSError *))completionHandler {
    _plottedPoints = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _mainChartView.frame.size.width, _mainChartView.frame.size.height)];
    
    double chartFrameWidth = self.view.frame.size.width - 45;
    double chartFrameHeight = _mainChartView.frame.size.height - (2 * _yAxisPadding);
    int dataPointRadius = 1.75;
    double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
    NSLog(@"[DEBUG] heartRateRange%f = _chartMax.doubleValue%f - _chartMin.doubleValue%f", heartRateRange, _chartMax.doubleValue, _chartMin.doubleValue);
    
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
            _kNoHRDataToDisplay = true;
            abort();
        } else if (results.count == 0) {
            _kNoHRDataToDisplay = true;
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
                double xCoordinate = ((sampleDuration * chartFrameWidth) / totalSleepDuration);
                
                // Calculate Y Coordinate
                double heartRate = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
                double adjustedRate = _chartMax.doubleValue - heartRate;
                double yCoordinate = ((adjustedRate * chartFrameHeight) / heartRateRange) + _yAxisPadding;
                UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(xCoordinate + 45 - dataPointRadius, _chartOrigin.y + yCoordinate - (dataPointRadius * 2), dataPointRadius * 2, dataPointRadius * 2)];
                CAShapeLayer *fillLayer = [CAShapeLayer layer];
                fillLayer.frame = CGRectMake(xCoordinate + 45, 100, dataPointRadius, dataPointRadius);
                fillLayer.bounds = CGRectMake(xCoordinate + 45, 100, dataPointRadius, dataPointRadius);
                fillLayer.path = circle.CGPath;
                fillLayer.strokeColor = [UIColor whiteColor].CGColor;
                fillLayer.fillColor = [UIColor whiteColor].CGColor;
                fillLayer.lineWidth = 1;
                fillLayer.lineJoin = kCALineJoinRound;
                [_plottedPoints.layer addSublayer:fillLayer];
                [self.view addSubview:_plottedPoints];
                
                if (indexCount > 0) {
                    [_pathHeartRate addLineToPoint:CGPointMake(xCoordinate, yCoordinate - dataPointRadius)];
                } else {
                    [_pathHeartRate moveToPoint:CGPointMake(xCoordinate, yCoordinate - dataPointRadius)];
                    
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
    NSLog(@"[DEBUG] %@ - chartPlotableSpace = %f", _detailSleepSession.name, chartPlotableSpace);
    
    if (_avgStatistic.result) {
        
        // heartRateRange will be used in conversion function
        double heartRateRange = _chartMax.doubleValue - _chartMin.doubleValue;
        NSLog(@"[DEBUG] %@ - %f(max) - %f(min) = %f(heartRateRange)", _detailSleepSession.name, _chartMax.doubleValue, _chartMin.doubleValue, heartRateRange);
        
        // adjustedRate stores the value for the difference between the top of the heartRateRange and the average
        double adjustedRate = _chartMax.doubleValue - floorf(_avgStatistic.result);
        NSLog(@"[DEBUG] %@ - %f(max) - %f(floor) = %f(adjustedRate)", _detailSleepSession.name, _chartMax.doubleValue, floorf(_avgStatistic.result), adjustedRate);
        NSLog(@"[DEBUG] %@ - _avgStatistic.result = %f", _detailSleepSession.name, _avgStatistic.result);
        
        // Converts the average heart rate to points for used in plotting on the chart. The points will represent the bottom of the chart to where the line should be plotted.
        double convertHeartRateToPoints = ((adjustedRate * chartPlotableSpace) / heartRateRange);
        NSLog(@"[DEBUG] %@ - convertHeartRateToPoints = %f", _detailSleepSession.name, convertHeartRateToPoints);
        
        // Create Average Heart Rate Line
        UIView *horizontalLine = [[UIView alloc]initWithFrame:CGRectMake(_mainChartView.frame.origin.x, _mainChartView.frame.origin.y + convertHeartRateToPoints + _yAxisPadding, self.view.bounds.size.width*2, 1)];
        [horizontalLine setBackgroundColor:[ColorConstants darkThemePrimaryAccentColor]];
        [self.view addSubview:horizontalLine];
    }
}

-(void)strokeHeartRatePathOnChart {
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.frame = CGRectMake(_chartOrigin.x, _chartOrigin.y, self.view.frame.size.width, self.view.frame.size.height);
    pathLayer.bounds = self.view.frame;
    pathLayer.path = _pathHeartRate.CGPath;
    pathLayer.strokeColor = [UIColor whiteColor].CGColor;
    pathLayer.fillColor = nil;
    pathLayer.lineWidth = 1;
    pathLayer.lineJoin = kCALineJoinRound;
    [_plottedPoints.layer addSublayer:pathLayer];
}

@end
