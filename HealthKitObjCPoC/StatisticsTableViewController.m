//
//  StatisticsTableViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/2/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "StatisticsTableViewController.h"
#import "session.h"
#import "Utility.h"
#import "SleepSession.h"
#import "SleepStatistic.h"
#import "StatisticsTableViewCell.h"

@interface StatisticsTableViewController () <NSFetchedResultsControllerDelegate, NSFetchedResultsControllerDelegate>

// Core Data Properties
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *convertedSessionsFromLastWeek;
@property (nonatomic, strong) NSMutableArray *lastSevenDaysStatistics;

@end

@implementation StatisticsTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self getLastWeeksSleepSessions];
    _lastSevenDaysStatistics = [self refreshStatistics:_convertedSessionsFromLastWeek];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:@"NewSessionAdded" object:nil];
    
    // this UIViewController is about to re-appear, make sure we remove the current selection in our table view
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
    
    // some other view controller could have changed our nav bar tint color, so reset it here
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3725490196 green:0.3058823529 blue:0.7176470588 alpha:1];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Remove extra separators from tableview
    self.tableView.tableFooterView = [UIView new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadTable:(NSNotification *)notification {
    [self getLastWeeksSleepSessions];
    NSLog(@"In ReloadTable method. Recieved notification: %@", notification);
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _lastSevenDaysStatistics.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor colorWithRed:0.5568627451 green:0.5568627451 blue:0.5568627451 alpha:1.0];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title1 = @"Last 7 Days";
    NSArray *titlesArray = [[NSArray alloc] initWithObjects:title1, nil];
    return [titlesArray objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"statViewCell";
    StatisticsTableViewCell *cell = (StatisticsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - Configuring table view cells

- (void)configureCell:(StatisticsTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    SleepStatistic *stat = [_lastSevenDaysStatistics objectAtIndex:indexPath.row];
    cell.statisticTitleLabel.text = stat.name;
    cell.statisticResultLabel.text = stat.stringResult;
}


#pragma mark - Statistics Methods

- (NSMutableArray *)refreshStatistics:(NSArray *)sleepSessions {
    SleepStatistic *timeToFallAsleep = [[SleepStatistic alloc] init];
    SleepStatistic *timesAwokeDuringSleep = [[SleepStatistic alloc] init];
    SleepStatistic *averageTimeAsleep = [[SleepStatistic alloc] init];
    SleepStatistic *totalTimeAsleep = [[SleepStatistic alloc] init];
    SleepStatistic *longestTimeAsleep = [[SleepStatistic alloc] init];
    SleepStatistic *shortestTimeAsleep = [[SleepStatistic alloc] init];
    
    double timeToFallAsleepSum = 0;
    int timesAwoke = 0;
    double totalTimeAsleepSumInSeconds = 0;
    double longestSleepSessionInSeconds = 0;
    double shortestSleepSessionInSeconds = 0;
    
    for (SleepSession *theSession in sleepSessions) {
        
        // Calculate Average Time to Fall Asleep
        timeToFallAsleep.name = [NSString stringWithFormat:@"Average Time To Fall Asleep"];
        NSDateComponents *timeToSleepComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[theSession.inBed firstObject] toDate:[theSession.sleep firstObject] options:0];
        NSInteger hours = [timeToSleepComponents hour];
        NSInteger minutes = [timeToSleepComponents minute];
        NSInteger seconds = [timeToSleepComponents second];
        
        double totalTimeInSeconds = 0;
        totalTimeInSeconds = (hours * 3600) + (minutes * 60) + seconds;
        timeToFallAsleepSum = timeToFallAsleepSum + totalTimeInSeconds;
        
        // Calculate Number of Times Awoke During Sleep
        timesAwokeDuringSleep.name = [NSString stringWithFormat:@"Awoke During Sleep"];
        if (theSession.wake.count > 1) {
            timesAwoke = timesAwoke + 1;
        }
        
        // Calculate Total Time Asleep
        averageTimeAsleep.name = [NSString stringWithFormat:@"Average"];
        
        // Calculate Total Time Asleep
        totalTimeAsleep.name = [NSString stringWithFormat:@"Total"];
        NSDateComponents *timeAsleepComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[theSession.sleep firstObject] toDate:[theSession.wake lastObject] options:0];
        hours = [timeAsleepComponents hour];
        minutes = [timeAsleepComponents minute];
        seconds = [timeAsleepComponents second];
        
        double totalTimeAsleepInSeconds = 0;
        totalTimeAsleepInSeconds = (hours * 3600) + (minutes * 60) + seconds;
        totalTimeAsleepSumInSeconds = totalTimeAsleepSumInSeconds + totalTimeAsleepInSeconds;
        
        // Longest Time Sleep
        longestTimeAsleep.name = [NSString stringWithFormat:@"Longest"];
        if (totalTimeAsleepInSeconds > longestSleepSessionInSeconds) {
            longestSleepSessionInSeconds = totalTimeAsleepInSeconds;
        }
        
        // Longest Time Sleep
        shortestTimeAsleep.name = [NSString stringWithFormat:@"Shortest"];
        if (shortestSleepSessionInSeconds == 0) {
            shortestSleepSessionInSeconds = totalTimeAsleepInSeconds;
        } else if (shortestSleepSessionInSeconds > totalTimeAsleepInSeconds) {
            shortestSleepSessionInSeconds = totalTimeAsleepInSeconds;
        }
        
    }
    
    timeToFallAsleep.result = (timeToFallAsleepSum / 60) / 7;
    timeToFallAsleep.stringResult = [NSString stringWithFormat:@"%.0fm", timeToFallAsleep.result];
    
    timesAwokeDuringSleep.result = timesAwoke;
    if (timesAwoke == 1) {
        timesAwokeDuringSleep.stringResult = [NSString stringWithFormat:@"%d time", timesAwoke];
    } else {
        timesAwokeDuringSleep.stringResult = [NSString stringWithFormat:@"%d times", timesAwoke];
    }
    
    averageTimeAsleep.result = totalTimeAsleepSumInSeconds / 7;
    averageTimeAsleep.stringResult = [Utility timeFormatter:averageTimeAsleep.result];
    
    totalTimeAsleep.result = totalTimeAsleepSumInSeconds;
    totalTimeAsleep.stringResult = [Utility timeFormatter:totalTimeAsleep.result];
    
    longestTimeAsleep.result = longestSleepSessionInSeconds;
    longestTimeAsleep.stringResult = [Utility timeFormatter:longestTimeAsleep.result];
    
    shortestTimeAsleep.result = shortestSleepSessionInSeconds;
    shortestTimeAsleep.stringResult = [Utility timeFormatter:shortestTimeAsleep.result];
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithObjects:timeToFallAsleep, timesAwokeDuringSleep, averageTimeAsleep, totalTimeAsleep, shortestTimeAsleep, longestTimeAsleep, nil];
    return results;
}


#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)initializeFetchedResultsController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Session"];
    
    NSSortDescriptor *creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    
    [request setSortDescriptors:@[creationDateSort]];
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    [self setFetchedResultsController:[[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:@"sectionByMonthAndYearUsingCreationDate" cacheName:nil]];
    [[self fetchedResultsController] setDelegate:self];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Failed to initialize FetchedResultsController: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
}

- (void)getLastWeeksSleepSessions {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Session"];
    
    // Results should be in descending order of timeStamp.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:7];
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSArray *results = [moc executeFetchRequest:request error:NULL];
    
    _convertedSessionsFromLastWeek = [Utility convertManagedObjectsToSleepSessions:results];
}

@end
