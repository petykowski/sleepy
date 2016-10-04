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

@interface StatisticsTableViewController () <NSFetchedResultsControllerDelegate, NSFetchedResultsControllerDelegate>

// Core Data Properties
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *convertedSessionsFromLastWeek;


@end

@implementation StatisticsTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self getLastWeeksSleepSessions];
    
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatisticCell" forIndexPath:indexPath];
    
    SleepStatistic *stat = [self calculateAverageTimeToFallAsleep:_convertedSessionsFromLastWeek];
    
    
    cell.textLabel.text = stat.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0fm", stat.result];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Statistics Methods

- (SleepStatistic *)calculateAverageTimeToFallAsleep:(NSArray *)sleepSessions {
    SleepStatistic *averageTimeToFallAsleep = [[SleepStatistic alloc] init];
    averageTimeToFallAsleep.name = [NSString stringWithFormat:@"Time To Fall Asleep"];
    
    double sum = 0;
    
    for (SleepSession *theSession in sleepSessions) {
        NSDateComponents *timeToSleepComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[theSession.inBed firstObject] toDate:[theSession.sleep firstObject] options:0];
        
        NSInteger hours = [timeToSleepComponents hour];
        NSInteger minutes = [timeToSleepComponents minute];
        NSInteger seconds = [timeToSleepComponents second];
        
        double totalTimeInSeconds = 0;
        totalTimeInSeconds = (hours * 3600) + (minutes * 60) + seconds;
        sum = sum + totalTimeInSeconds;
    }
    
    averageTimeToFallAsleep.result = sum / 7;
    
    return averageTimeToFallAsleep;
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
