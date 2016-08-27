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
#import "session.h"
#import "AppDelegate.h"


@interface SessionsTableViewController () <WCSessionDelegate>
- (IBAction)debugCoreData:(id)sender;
- (IBAction)fetchCoreData:(id)sender;
- (IBAction)deleteCoreData:(id)sender;

// core data test
@property (strong) NSMutableArray *devices;

@end

@implementation SessionsTableViewController {
    NSMutableArray *sampleObjects;
    NSMutableArray *sessionTitles;
    NSManagedObject *sleepExample;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    sessionTitles = [NSMutableArray arrayWithObjects:@"August 25", @"August 24", @"August 23", @"August 22", nil];
    sampleObjects = [NSMutableArray arrayWithObjects:@"10:45 PM", @"11:12 PM", @"7:45 AM", @"7:53 AM", nil];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSArray *)message replyHandler:(nonnull void (^)(NSDictionary * __nonnull))replyHandler {
    NSDictionary *sleepSession = message;
    NSArray *names = [NSArray arrayWithObject:[sleepSession objectForKey:@"Name"]];
    NSArray *start = [NSArray arrayWithObject:[sleepSession objectForKey:@"Start"]];
    
    NSLog(@"[DEBUG] the contents of name array in iOS is: %@", names);
    NSLog(@"[DEBUG] the contents of start array in iOS is: %@", start);
    
    //    Use this to update the UI instantaneously (otherwise, takes a little while)
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [sessionTitles addObject:[names lastObject]];
        [sampleObjects addObject:[start lastObject]];
        [self.tableView reloadData];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [sessionTitles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *sessionsIdentifier = @"sessions";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sessionsIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sessionsIdentifier];
    }
    
    cell.textLabel.text = [sessionTitles objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [sampleObjects objectAtIndex:indexPath.row];
    
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

// Sets Managed Object
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (IBAction)debugCoreData:(id)sender {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    // Create a new managed object
    NSManagedObject *newDevice = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:context];
    [newDevice setValue:@"August 26th" forKey:@"name"];
    [newDevice setValue:[NSDate date] forKey:@"inBedStart"];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

- (IBAction)fetchCoreData:(id)sender {
    // Fetch the devices from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Session"];
    self.devices = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSLog(@"[DEBUG] contents of coreData: %@ and %@", [self.devices valueForKey:@"name"], [self.devices valueForKey:@"inBedStart"]);
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
@end
