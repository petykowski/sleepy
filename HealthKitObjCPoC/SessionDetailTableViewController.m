//
//  SessionDetailTableViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/17/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SessionDetailTableViewController.h"
#import "SessionDetailTableViewCell.h"
#import "Utility.h"

@interface SessionDetailTableViewController ()

@property NSDictionary *sleepSessionDetails;
@property NSMutableArray *sleepSessionMilestones;

@end

@implementation SessionDetailTableViewController

@synthesize sleepSession;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sleepSessionDetails = [Utility convertManagedObjectSessionToDictionaryForDetailView:sleepSession];
    _sleepSessionMilestones = [Utility convertAndPopulateSleepSessionDataForMilestone:_sleepSessionDetails];
    [self.navigationItem setTitle:[_sleepSessionDetails objectForKey:@"creationDate"]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSUInteger cell = 0;
    
    if (section == 0) {
        cell = _sleepSessionMilestones.count;
    } else {
        cell = 2;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor colorWithRed:0.5568627451 green:0.5568627451 blue:0.5568627451 alpha:1.0];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title1 = @"Sleep";
    NSString *title2 = @"Stats";
    NSArray *titlesArray = [[NSArray alloc] initWithObjects:title1, title2, nil];
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
    
    static NSDateFormatter *dateFormatter = nil;
    static NSDateFormatter *timeFormatter = nil;
    
    NSMutableArray *inBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.inBed];
    NSMutableArray *sleepArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.sleep];
    NSMutableArray *wakeArrary = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.wake];
    NSMutableArray *outBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.outBed];
    
    NSDateComponents *components;
    
    dateFormatter = [Utility dateFormatterForCellLabel];
    timeFormatter = [Utility dateFormatterForTimeLabels];
    
    NSArray *titleArray = [NSArray arrayWithObjects:@"In Bed", @"Asleep", @"Awake", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", nil];
    
    NSArray *statsTitleArray = [NSArray arrayWithObjects:@"Duration", @"Fell Asleep", nil];
    
    // Configure Sleep Details Here
    if (indexPath.section == 0) {
        cell.eventTitleLabel.text = [titleArray objectAtIndex:indexPath.row];
        cell.eventTimeLabel.text = [_sleepSessionMilestones objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        cell.eventTitleLabel.text = [statsTitleArray objectAtIndex:indexPath.row];
        
        // Configures Sleep Stats Here
        
        if (indexPath.row == 0) {
            components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[sleepArray firstObject] toDate:[wakeArrary lastObject] options:0];
            NSInteger hours = [components hour];
            NSInteger minutes = [components minute];
            if (hours == 0) {
                if (minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld minute", (long)minutes];
                } else {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld minutes", (long)minutes];
                }
            } else if (hours > 0) {
                if (hours == 1 && minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hour and %ld minute", (long)hours, (long)minutes];
                } else if (minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hours and %ld minute", (long)hours, (long)minutes];
                } else if (hours == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hour and %ld minutes", (long)hours, (long)minutes];
                } else {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hours and %ld minutes", (long)hours, (long)minutes];
                }
            }
        } else if (indexPath.row == 1) {
            components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[inBedArray firstObject] toDate:[sleepArray firstObject] options:0];
            NSInteger hours = [components hour];
            NSInteger minutes = [components minute];
            if (hours == 0) {
                if (minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld minute", (long)minutes];
                } else {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld minutes", (long)minutes];
                }
            } else if (hours > 0) {
                if (hours == 1 && minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hour and %ld minute", (long)hours, (long)minutes];
                } else if (minutes == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hours and %ld minute", (long)hours, (long)minutes];
                } else if (hours == 1) {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hour and %ld minutes", (long)hours, (long)minutes];
                } else {
                    cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ld hours and %ld minutes", (long)hours, (long)minutes];
                }
            }
        }
        
        
        
        
    }
}

@end
