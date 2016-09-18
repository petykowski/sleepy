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
    
    _sleepSessionDetails = [Utility convertSessionToDictionary:sleepSession];
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
    
    int cell = 0;
    
    if (section == 0) {
        cell = _sleepSessionMilestones.count;
    } else {
        cell = 1;
    }
    
    return cell;
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
    
    NSMutableArray *inBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.sleep];
    NSMutableArray *outBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.sleepSession.wake];
    
    NSDateComponents *components;
    
    components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[inBedArray firstObject] toDate:[outBedArray lastObject] options:0];
    
    NSInteger hours = [components hour];
    NSInteger minutes = [components minute];
    
    dateFormatter = [Utility dateFormatterForCellLabel];
    timeFormatter = [Utility dateFormatterForTimeLabels];
    
    NSArray *titleArray = [NSArray arrayWithObjects:@"In Bed", @"Asleep", @"Awake", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", @"Out Bed", @"Back To Bed", @"Back To Sleep", @"Awake", @"Out Bed", nil];
    
    NSArray *statsTitleArray = [NSArray arrayWithObjects:@"Duration", nil];
    
    if (indexPath.section == 0) {
        cell.eventTitleLabel.text = [titleArray objectAtIndex:indexPath.row];
        cell.eventTimeLabel.text = [_sleepSessionMilestones objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        cell.eventTitleLabel.text = [statsTitleArray objectAtIndex:indexPath.row];
        if (hours == 0) {
            cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ldm", (long)minutes];
        } else if (hours > 0) {
            cell.eventTimeLabel.text = [NSString stringWithFormat:@"%ldh %ldm", (long)hours, (long)minutes];
        }
    }
}

@end
