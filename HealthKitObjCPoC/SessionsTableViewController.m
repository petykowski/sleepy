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


@interface SessionsTableViewController () <WCSessionDelegate, NSFetchedResultsControllerDelegate>

// Debug Core Data
- (IBAction)debugCoreData:(id)sender;
- (IBAction)fetchCoreData:(id)sender;
- (IBAction)deleteCoreData:(id)sender;

// core data test
@property (strong) NSMutableArray *devices;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation SessionsTableViewController {
    NSMutableArray *sampleObjects;
    NSMutableArray *sessionTitles;
    NSManagedObject *sleepExample;
    NSString *segueTest;
}

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    [self initializeCoreData];
    
    return self;
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Watch Connectivity

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    NSDictionary *sleepSession = message;
    NSArray *names = [NSArray arrayWithObject:[sleepSession objectForKey:@"Name"]];
    NSArray *start = [NSArray arrayWithObject:[sleepSession objectForKey:@"Start"]];
    
    NSLog(@"[DEBUG] the contents of name array in iOS is: %@", names);
    NSLog(@"[DEBUG] the contents of start array in iOS is: %@", start);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [sessionTitles addObject:[names lastObject]];
        [sampleObjects addObject:[start lastObject]];
        [self.tableView reloadData];
    });
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
//    NSManagedObjectContext *context = [self managedObjectContext];
//    
//    // Create a new managed object
//    NSManagedObject *newDevice = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:context];
//    [newDevice setValue:@"August 26th" forKey:@"name"];
//    [newDevice setValue:[NSDate date] forKey:@"inBedStart"];
//    
//    NSError *error = nil;
//    // Save the object to persistent store
//    if (![context save:&error]) {
//        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
//    }
    
    session *sleepSession = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:[self managedObjectContext]];
    
    sleepSession.name = @"This is the Session Name";
    
    NSError *error = nil;
    if ([[self managedObjectContext] save:&error] == NO) {
        NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
}

- (IBAction)fetchCoreData:(id)sender {
    // Fetch the devices from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Session"];
    self.devices = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSLog(@"[DEBUG] contents of coreData object: %@", self.devices);
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


// Core Data 8/29

- (void)initializeCoreData
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"coreData" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom != nil, @"Error initializing Managed Object Model");
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    [self setManagedObjectContext:moc];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"DataModel.sqlite"];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSError *error = nil;
        NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
        NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        NSAssert(store != nil, @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
    });
}

@end
