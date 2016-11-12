//
//  SessionDetailTableViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/17/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <HealthKit/HealthKit.h>
#import "AppDelegate.h"
#import "SessionDetailTableViewController.h"
#import "SessionDetailTableViewCell.h"
#import "Utility.h"
#import "SleepStatistic.h"
#import "SleepSession.h"
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"
#import "HeartRateChart.h"
#import "Constants.h"


@interface SessionDetailTableViewController ()

@property NSMutableArray *sleepSessionMilestones;
@property NSMutableArray *sleepStatistics;
@property NSMutableArray *heartRateStatistics;
@property SleepSession *detailSleepSession;
@property (nonatomic, strong) IBOutlet HeartRateChart *chartWithDates;
@property NSArray *ktimes12Hour;

@end

@implementation SessionDetailTableViewController

@synthesize sleepSession;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ktimes12Hour = @[@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM", @"9 AM", @"10 AM", @"11 AM", @"12 PM", @"1 PM", @"2 PM", @"3 PM", @"4 PM", @"5 PM", @"6 PM", @"7 PM", @"8 PM", @"9 PM", @"10 PM", @"11 PM"];
    
    _heartRateStatistics = [[NSMutableArray alloc] init];
    _sleepStatistics = [[NSMutableArray alloc] init];
    _detailSleepSession = [Utility convertManagedObjectSessionToSleepSessionForDetailView:sleepSession];
    _sleepSessionMilestones = [Utility convertAndPopulatePreviousSleepSessionDataForMilestone:_detailSleepSession];
    [self loadChartWithData];
    [self refreshHealthStatistics];
    [self refreshSleepStatistics];
    [self.navigationItem setTitle:_detailSleepSession.name];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSUInteger cell = 0;
    
    if (section == 0) {
        cell = _sleepSessionMilestones.count;
    } else if (section == 1){
        cell = _sleepStatistics.count;
    } else if (section == 2){
        cell = _heartRateStatistics.count;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor colorWithRed:0.5568627451 green:0.5568627451 blue:0.5568627451 alpha:1.0];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title1 = @"Milestones";
    NSString *title2 = @"Stats";
    NSString *title3 = @"Heart Rate";
    NSArray *titlesArray = [[NSArray alloc] initWithObjects:title1, title2, title3, nil];
    return [titlesArray objectAtIndex:section];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"detailViewCell";
    SessionDetailTableViewCell *cell = (SessionDetailTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}


#pragma mark - Configuring table view cells

- (void)configureCell:(SessionDetailTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *titleArray = [NSArray arrayWithObjects:@"In Bed", @"Asleep", @"Awake", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", nil];
    
    if (indexPath.section == 0) {
        cell.eventTitleLabel.text = [titleArray objectAtIndex:indexPath.row];
        cell.eventTimeLabel.text = [_sleepSessionMilestones objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        SleepStatistic *sleepStat = [_sleepStatistics objectAtIndex:indexPath.row];
        cell.eventTitleLabel.text = sleepStat.name;
        cell.eventTimeLabel.text = sleepStat.stringResult;
    } else if (indexPath.section == 2){
        SleepStatistic *sleepStat = [_heartRateStatistics objectAtIndex:indexPath.row];
        cell.eventTitleLabel.text = sleepStat.name;
        cell.eventTimeLabel.text = [NSString stringWithFormat:@"%.0f bpm", sleepStat.result];
    }
}

#pragma mark -  Chart

- (void)loadChartWithData {
    NSDateComponents *durationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[_detailSleepSession.sleep firstObject] toDate:[_detailSleepSession.wake lastObject] options:0];
    NSInteger durationHours = [durationComponents hour];
    NSInteger durationMinutes = [durationComponents minute];
    
    NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[_detailSleepSession.sleep firstObject]];
    NSInteger startHour = [startComponents hour];
    
    NSMutableArray *timeMilestones = [[NSMutableArray alloc] init];
    
    int x = 0;
    
    // Allows chart to display label for the last hour of sleep in chart
    if (durationMinutes > 0) {
        durationHours = durationHours + 1;
        NSLog(@"[DEBUG] durationMinutes = %ld", (long)durationMinutes);
        NSLog(@"[DEBUG] durationHours = %ld", (long)durationHours);
    }
    
    while (x <= durationHours) {
        if (startHour > _ktimes12Hour.count - 1) {
            startHour = startHour - [_ktimes12Hour count];
        }
        [timeMilestones addObject:_ktimes12Hour[startHour]];
        startHour++;
        x++;
    }
    NSLog(@"[DEBUG] timeMilestones = %@", timeMilestones);
    _chartWithDates.datesArray = timeMilestones;
    [_chartWithDates setChartData];
    
}

#pragma mark - Sleep Statistics

- (void)refreshSleepStatistics {
    static NSDateFormatter *dateFormatter = nil;
    static NSDateFormatter *timeFormatter = nil;
    
    dateFormatter = [Utility dateFormatterForCellLabel];
    timeFormatter = [Utility dateFormatterForTimeLabels];
    
    NSDateComponents *durationComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[_detailSleepSession.sleep firstObject] toDate:[_detailSleepSession.wake lastObject] options:0];
    
    NSDateComponents *timeToSleepComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[_detailSleepSession.inBed firstObject] toDate:[_detailSleepSession.sleep firstObject] options:0];
    
    NSArray *componentsArrary = [[NSArray alloc] initWithObjects:durationComponents, timeToSleepComponents, nil];
    
    int count = 0;
    for (NSDateComponents *components in componentsArrary) {
        SleepStatistic *sleepDuration = [[SleepStatistic alloc] init];
        if (count == 0){
            sleepDuration.name = [NSString stringWithFormat:@"Duration"];
        } else {
            sleepDuration.name = [NSString stringWithFormat:@"Fell Asleep"];
        }
        NSInteger hours = [components hour];
        NSInteger minutes = [components minute];
        if (hours == 0) {
            if (minutes == 1) {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld minute", (long)minutes];
            } else {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld minutes", (long)minutes];
            }
        } else if (hours > 0) {
            if (hours == 1 && minutes == 1) {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld hour and %ld minute", (long)hours, (long)minutes];
            } else if (minutes == 1) {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld hours and %ld minute", (long)hours, (long)minutes];
            } else if (hours == 1) {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld hour and %ld minutes", (long)hours, (long)minutes];
            } else {
                sleepDuration.stringResult = [NSString stringWithFormat:@"%ld hours and %ld minutes", (long)hours, (long)minutes];
            }
        }
        [_sleepStatistics addObject:sleepDuration];
        count++;
    }
   
}


#pragma mark - HealthKit Statistics

- (NSPredicate *)predicateForSleepDuration {
    
    return [HKQuery predicateForSamplesWithStartDate:[_detailSleepSession.sleep firstObject] endDate:[_detailSleepSession.wake lastObject] options:HKQueryOptionNone];
}

- (void)refreshHealthStatistics {
    [self getMinHeartRateForSleepSession:^(NSError *error) {
        [self getMaxHeartRateForSleepSession:^(NSError *error) {
            [self getAverageHeartRateForSleepSession:^(NSError *error) {
                [self.tableView reloadData];
            }];
        }];
        
    }];
}

- (void)getAverageHeartRateForSleepSession:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKStatisticsQuery *averageHeartRateQuery = [[HKStatisticsQuery alloc] initWithQuantityType:heartRateQuantityType quantitySamplePredicate:predicate options:HKStatisticsOptionDiscreteAverage completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SleepStatistic *avgHeartRate = [[SleepStatistic alloc] init];
            
            avgHeartRate.result = [result.averageQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
            avgHeartRate.name = [NSString stringWithFormat:@"Average"];
            
            [_heartRateStatistics addObject:avgHeartRate];
            
            if (completionHandler) {
                completionHandler(error);
            }
        });
    }];
    
    [self.healthStore executeQuery:averageHeartRateQuery];
}

- (void)getMinHeartRateForSleepSession:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKStatisticsQuery *minHeartRateQuery = [[HKStatisticsQuery alloc] initWithQuantityType:heartRateQuantityType quantitySamplePredicate:predicate options:HKStatisticsOptionDiscreteMin completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SleepStatistic *minHeartRate = [[SleepStatistic alloc] init];
            
            minHeartRate.result = [result.minimumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
            minHeartRate.name = [NSString stringWithFormat:@"Minimum"];
            
            [_heartRateStatistics addObject:minHeartRate];
            
            if (completionHandler) {
                completionHandler(error);
            }
        });
    }];
    
    [self.healthStore executeQuery:minHeartRateQuery];
}

- (void)getMaxHeartRateForSleepSession:(void (^)(NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSleepDuration];
    HKQuantityType *heartRateQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKStatisticsQuery *maxHeartRateQuery = [[HKStatisticsQuery alloc] initWithQuantityType:heartRateQuantityType quantitySamplePredicate:predicate options:HKStatisticsOptionDiscreteMax completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SleepStatistic *maxHeartRate = [[SleepStatistic alloc] init];
            
            maxHeartRate.result = [result.maximumQuantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
            maxHeartRate.name = [NSString stringWithFormat:@"Maximum"];
            
            [_heartRateStatistics addObject:maxHeartRate];
            
            if (completionHandler) {
                completionHandler(error);
            }
        });
    }];
    
    [self.healthStore executeQuery:maxHeartRateQuery];
}

@end
