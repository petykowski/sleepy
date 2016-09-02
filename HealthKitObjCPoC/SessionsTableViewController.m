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
#import "SessionDetailViewController.h"
#import "session.h"
#import "Utility.h"


@interface SessionsTableViewController () <WCSessionDelegate, NSFetchedResultsControllerDelegate, NSFetchedResultsControllerDelegate>



// core data test
@property (strong) NSMutableArray *devices;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) session *object;
@property (nonatomic, strong) session *objectToSave;

@end

@implementation SessionsTableViewController {
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

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    
    
    NSDictionary *sleepSession = message;
    
    self.objectToSave = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:[self managedObjectContext]];
    self.objectToSave.name = [sleepSession objectForKey:@"name"];
    self.objectToSave.creationDate = [sleepSession objectForKey:@"creationDate"];
    self.objectToSave.inBed = [sleepSession objectForKey:@"inBed"];
    self.objectToSave.sleep = [sleepSession objectForKey:@"sleep"];
    self.objectToSave.wake = [sleepSession objectForKey:@"wake"];
    self.objectToSave.outBed = [sleepSession objectForKey:@"outBed"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if ([[self managedObjectContext] save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    });
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> *replyMessage))replyHandler {
    NSString *request = [message objectForKey:@"Request"];
    NSString *actionPerformed;
    if ([request  isEqual: @"getData"]) {
        NSLog(@"[DEBUG] Perform this request!!!!");
        [self getMostRecentSleepSessionForWatchOS];
        actionPerformed = @"Here's your data back!";
        
    }
    replyHandler(@{@"actionPerformed":actionPerformed});
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
    return [[[self fetchedResultsController] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id< NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *sessionsIdentifier = @"sessions";
    
    NSDateFormatter *dateFormatter = [Utility dateFormatterForCellLabel];
    NSDateFormatter *timeFormatter = [Utility dateFormatterForTimeLabels];
    
    self.object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSMutableArray *inBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.object.inBed];
    NSMutableArray *outBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.object.outBed];
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sessionsIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sessionsIdentifier];
    }
    
    cell.textLabel.text = [dateFormatter stringFromDate:self.object.creationDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [timeFormatter stringFromDate:[inBedArray lastObject]], [timeFormatter stringFromDate:[outBedArray lastObject]]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:managedObject];
        [self.managedObjectContext save:nil];
    }
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

/*

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    
    NSManagedObjectContext *moc = self.managedObjectContext; //Retrieve the main queue NSManagedObjectContext
    
    [self setFetchedResultsController:[[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil]];
    [[self fetchedResultsController] setDelegate:self];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Failed to initialize FetchedResultsController: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
}

- (void)getMostRecentSleepSessionForWatchOS {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Session"];
    
    // Results should be in descending order of timeStamp.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    NSArray *results = [moc executeFetchRequest:request error:NULL];
    session *latestEntity = [results objectAtIndex:0];
    
    NSLog(@"[DEBUG] The most recenet entity: %@", latestEntity);
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
