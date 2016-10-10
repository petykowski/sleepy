//
//  SessionsTableViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/25/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "SessionsTableViewController.h"
#import "AppDelegate.h"
#import "session.h"
#import "Utility.h"
#import "SleepSessionTableViewCell.h"
#import "SleepSession.h"
#import "SessionDetailTableViewController.h"


@interface SessionsTableViewController () <WCSessionDelegate, NSFetchedResultsControllerDelegate, NSFetchedResultsControllerDelegate>



// core data test
@property (strong) NSMutableArray *devices;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) session *object;
@property (nonatomic, strong) session *objectToSave;
@property (nonatomic, strong) session *mostRecentSleepSession;

@end

@implementation SessionsTableViewController {
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // this UIViewController is about to re-appear, make sure we remove the current selection in our table view
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:NO];
    
    // some other view controller could have changed our nav bar tint color, so reset it here
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.3725490196 green:0.3058823529 blue:0.7176470588 alpha:1];
    
    if (_loadedFromShortcut) {
        [self displayMostRecentSleepSession];
    }
}

- (void)displayMostRecentSleepSession {
    _loadedFromShortcut = false;
    NSIndexPath *selectedCellIndexPath= [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:selectedCellIndexPath animated:false scrollPosition:UITableViewScrollPositionNone];
    [self performSegueWithIdentifier:@"DetailSegue" sender:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeFetchedResultsController];
    
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    // Remove extra separators from tableview
    self.tableView.tableFooterView = [UIView new];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Watch Connectivity

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> *replyMessage))replyHandler {
    NSString *request = [message objectForKey:@"Request"];
    NSDictionary *response;
    NSLog(@"[DEBUG] Recieved Request.");
    
    if ([request  isEqual: @"getMostRecentSleepSessionForWatchOS"]) {
        self.mostRecentSleepSession = [self getMostRecentSleepSessionForWatchOS];
        if (self.mostRecentSleepSession != nil) {
            response = [self populateDictionaryWithSleepSessionData:self.mostRecentSleepSession];
            replyHandler(@{@"reply":response});
        } else {
            replyHandler(@{@"reply":@"No Data"});
            NSLog(@"[DEBUG] No data to provide.");
        }
    } else if ([request  isEqual: @"sendSleepSessionDataToiOSApp"]) {
        NSLog(@"[DEBUG] SAVING SLEEP DATA");
        NSDictionary *sleepSession = message;
        
        self.objectToSave = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:[self managedObjectContext]];
        self.objectToSave.name = [sleepSession objectForKey:@"name"];
        self.objectToSave.creationDate = [sleepSession objectForKey:@"creationDate"];
        self.objectToSave.inBed = [sleepSession objectForKey:@"inBed"];
        self.objectToSave.sleep = [sleepSession objectForKey:@"sleep"];
        self.objectToSave.wake = [sleepSession objectForKey:@"wake"];
        self.objectToSave.outBed = [sleepSession objectForKey:@"outBed"];
        
       [[NSNotificationCenter defaultCenter] postNotificationName:@"NewSessionAdded" object:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            if ([[self managedObjectContext] save:&error] == NO) {
                NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
            } else {
                replyHandler(@{@"reply":@"Saved Sucessfully!"});
            }
        });
        
    } else {
        NSLog(@"[DEBUG] Could not determine iOS request from Watch App.");
    }
}

- (NSMutableDictionary *)populateDictionaryWithSleepSessionData: (session *)mostRecentSleepSession{
    NSMutableDictionary *sleepSessionDictionary = [[NSMutableDictionary alloc] init];
    
    [sleepSessionDictionary setObject:@"Sleep Session" forKey:@"name"];
    [sleepSessionDictionary setObject:[NSDate date] forKey:@"creationDate"];
    [sleepSessionDictionary setObject:mostRecentSleepSession.inBed forKey:@"inBed"];
    [sleepSessionDictionary setObject:mostRecentSleepSession.sleep forKey:@"sleep"];
    [sleepSessionDictionary setObject:mostRecentSleepSession.wake forKey:@"wake"];
    [sleepSessionDictionary setObject:mostRecentSleepSession.outBed forKey:@"outBed"];
    
    return sleepSessionDictionary;
}

-(void)sessionDidBecomeInactive:(WCSession *)session {
    
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    NSLog(@"[DEBUG] WatchConnectivity Session state: %ld", activationState);
}

-(void)sessionDidDeactivate:(WCSession *)session {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if ([[[self fetchedResultsController] sections] count] != 0)
    {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else
    {
        UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        noDataLabel.text = @"No sleep data available. Start a sleep session on Apple Watch and check back here in the morning!";
        noDataLabel.lineBreakMode = NSLineBreakByWordWrapping;
        noDataLabel.numberOfLines = 0;
        noDataLabel.textColor = [UIColor whiteColor];
        noDataLabel.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = noDataLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    
    
    return [[[self fetchedResultsController] sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.textLabel.textColor = [UIColor whiteColor];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id< NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SleepSessionCell";
    SleepSessionTableViewCell *cell = (SleepSessionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:managedObject];
        [self.managedObjectContext save:nil];
    }
}

#pragma mark - Configuring table view cells

- (void)configureCell:(SleepSessionTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    UIView *cellSelectedColorView = [[UIView alloc] init];
    cellSelectedColorView.backgroundColor = [UIColor colorWithRed:0.2117647059 green:0.2117647059 blue:0.2117647059 alpha:1];
    [cell setSelectedBackgroundView:cellSelectedColorView];
    
    static NSDateFormatter *dateFormatter = nil;
    static NSDateFormatter *timeFormatter = nil;
    
    NSDateComponents *components;
    
    dateFormatter = [Utility dateFormatterForCellLabel];
    timeFormatter = [Utility dateFormatterForTimeLabels];
    
    self.object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSMutableArray *inBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.object.sleep];
    NSMutableArray *outBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.object.wake];
    
    components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[inBedArray firstObject] toDate:[outBedArray lastObject] options:0];
    
    NSInteger hours = [components hour];
    NSInteger minutes = [components minute];
    
    cell.sessionLabel.text = [dateFormatter stringFromDate:self.object.creationDate];
    
    if (hours == 0) {
        cell.sessionDurationLabel.text = [NSString stringWithFormat:@"%ldm", (long)minutes];
    } else if (hours > 0) {
        cell.sessionDurationLabel.text = [NSString stringWithFormat:@"%ldh %ldm", (long)hours, (long)minutes];
    }
    
    cell.sleepStartLabel.text = [timeFormatter stringFromDate:[inBedArray firstObject]];
    cell.sleepEndLabel.text = [timeFormatter stringFromDate:[outBedArray lastObject]];
    cell.sleepIconImageView.image = [UIImage imageNamed:@"SleepIcon"];
    cell.wakeIconImageView.image = [UIImage imageNamed:@"WakeIcon"];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"DetailSegue"]) {
        
        SessionDetailTableViewController *detailViewController = [segue destinationViewController];
        session *sleepSession = nil;
        
        if ([detailViewController respondsToSelector:@selector(setHealthStore:)]) {
            [detailViewController setHealthStore:self.healthStore];
        }
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        sleepSession = (session *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        detailViewController.sleepSession = sleepSession;
    }
}

#pragma mark - CoreData Stack

// Sets Managed Object
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

// Sets Managed Object
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

- (session *)getMostRecentSleepSessionForWatchOS {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Session"];
    
    // Results should be in descending order of timeStamp.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    NSArray *results = [moc executeFetchRequest:request error:NULL];
    session *latestEntity;
    
    if (!results || !results.count){
        return nil;
    } else {
        latestEntity = [results objectAtIndex:0];
    }

    return latestEntity;
}

- (IBAction)deleteCoreData:(id)sender {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *allCars = [[NSFetchRequest alloc] init];
    [allCars setEntity:[NSEntityDescription entityForName:@"Session" inManagedObjectContext:managedObjectContext]];
    [allCars setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *cars = [managedObjectContext executeFetchRequest:allCars error:&error];
    NSLog(@"[DEBUG] Print Array: %@", cars);
    //error handling goes here
    for (NSManagedObject *car in cars) {
        [managedObjectContext deleteObject:car];
    }
    NSError *saveError = nil;
    [managedObjectContext save:&saveError];
    //more error handling here
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] endUpdates];
}

@end
