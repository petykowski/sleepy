//
//  AppDelegate.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "SessionsTableViewController.h"
#import "OnboardingContentViewController.h"
#import "OnboardingViewController.h"
@import HealthKit;

@interface AppDelegate ()

@property (nonatomic, retain) HKHealthStore *healthStore;
@property (nonatomic, readwrite) BOOL hasAccessToSleepData;
@end

static NSString * const kUserHasOnboardedKey = @"user_has_onboarded";

@implementation AppDelegate


#pragma mark - CoreData Properties

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize persistentContainer = _persistentContainer;


#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    application.statusBarStyle = UIStatusBarStyleLightContent;
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    [self setUpHealthStoreForViewControllers];
    
    // determine if the user has onboarded yet or not
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];
    
    if (userHasOnboarded) {
        // Do Nothing
    }
    else {
        self.window.rootViewController = [self generateStandardOnboardingVC];
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}


#pragma mark - HealthKit

- (void)applicationShouldRequestHealthAuthorization:(UIApplication *)application {
    [self.healthStore handleAuthorizationForExtensionWithCompletion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed with error: %@", error);
        }
    }];
    
}

- (void)requestAccessToHealthKit {
    NSArray *readTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    NSArray *writeTypes = @[[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"[DEBUG] Failed attempt to request access to Health.app with error: %@", error);
        }
    }];
}

- (void)setUpHealthStoreForViewControllers {
    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];
    NSArray *navigationControllers = tabBarController.viewControllers;
    
    // Iterates through UINavigationControllers looking for their child UIViewControllers
    for (UINavigationController *navigationController in navigationControllers) {
        NSArray *viewControllers = navigationController.viewControllers;
        for (id viewController in viewControllers) {
            
            // Determines if child UIViewController has a setable HKHealthStore and sets it if true
            if ([viewController respondsToSelector:@selector(setHealthStore:)]) {
                [viewController setHealthStore:self.healthStore];
                NSLog(@"[DEBUG] Set HealthStore for %@", viewController);
            }
        }
    }
}


#pragma mark - On Boarding

- (void)setupNormalRootViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"Main Application"];
    [self.window.rootViewController presentViewController:mainViewController animated:YES completion:NULL];
}

- (void)handleOnboardingCompletion {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    [self setupNormalRootViewController];
}

- (OnboardingViewController *)generateStandardOnboardingVC {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *sleepyMainPath = [bundle pathForResource:@"SleepyMain" ofType:@"mp4"];
    NSString *healthKitPath = [bundle pathForResource:@"HealthKit" ofType:@"mp4"];
    NSString *appleWatchPath = [bundle pathForResource:@"SleepyWatch" ofType:@"mp4"];
    NSURL *sleepyMainMovieURL = [NSURL fileURLWithPath:sleepyMainPath];
    NSURL *healthKitMovieURL = [NSURL fileURLWithPath:healthKitPath];
    NSURL *appleWatchMovieURL = [NSURL fileURLWithPath:appleWatchPath];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]];
    NSInteger currentHour = [components hour];
    NSString *greeting;
    
    if (currentHour > 5 && currentHour < 12 ) {
        greeting = [NSString stringWithFormat:@"Good Morning!"];
    } else if (currentHour > 12 && currentHour < 18) {
        greeting = [NSString stringWithFormat:@"Good Afternoon!"];
    } else {
        greeting = [NSString stringWithFormat:@"Good Evening!"];
    }
    
    OnboardingContentViewController *firstPage = [OnboardingContentViewController contentWithTitle:greeting body:@"Sleepy is a sleep tracking app that helps users make sense of their sleep patterns." videoURL:sleepyMainMovieURL buttonText:nil action:nil];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ){
        
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if( screenHeight < screenWidth ){
            screenHeight = screenWidth;
        }
        
        if( screenHeight > 480 && screenHeight < 667 ){
            NSLog(@"iPhone 5/5s");
            firstPage.topPadding = 0;
            firstPage.underIconPadding = 50;
            firstPage.underTitlePadding = 225;
        } else if ( screenHeight > 480 && screenHeight < 736 ){
            NSLog(@"iPhone 6");
            firstPage.topPadding = 0;
            firstPage.underIconPadding = 65;
            firstPage.underTitlePadding = 361;
        } else if ( screenHeight > 480 ){
            firstPage.topPadding = 0;
            firstPage.underIconPadding = 75;
            firstPage.underTitlePadding = 375;
            NSLog(@"iPhone 6 Plus");
        } else {
            NSLog(@"iPhone 4/4s");
        }
    }
    
    
    OnboardingContentViewController *secondPage = [OnboardingContentViewController contentWithTitle:@"Integrate with HealthKit" body:@"Allowing access to HealthKit allows Sleepy to determine when you've fallen asleep and build sleep trends." videoURL:healthKitMovieURL buttonText:@"Enable HealthKit Access" action:^{
        if (_hasAccessToSleepData == 0) {
            [self requestAccessToHealthKit];
        }
    }];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ){
        
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if( screenHeight < screenWidth ){
            screenHeight = screenWidth;
        }
        
        if( screenHeight > 480 && screenHeight < 667 ){
            NSLog(@"iPhone 5/5s");
            secondPage.topPadding = 0;
            secondPage.underIconPadding = 50;
            secondPage.underTitlePadding = 225;
        } else if ( screenHeight > 480 && screenHeight < 736 ){
            NSLog(@"iPhone 6");
            secondPage.topPadding = 0;
            secondPage.underIconPadding = 65;
            secondPage.underTitlePadding = 316;
        } else if ( screenHeight > 480 ){
            secondPage.topPadding = 0;
            secondPage.underIconPadding = 75;
            secondPage.underTitlePadding = 375;
            NSLog(@"iPhone 6 Plus");
        } else {
            NSLog(@"iPhone 4/4s");
        }
    }
    
    OnboardingContentViewController *thirdPage = [OnboardingContentViewController contentWithTitle:@"Start Sleeping Smarter" body:@"When using the Sleepy watch app, 3D Touch to begin a new sleep session, and then again to wake." videoURL:appleWatchMovieURL buttonText:@"Get Started" action:^{
        [self handleOnboardingCompletion];
    }];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ){
        
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if( screenHeight < screenWidth ){
            screenHeight = screenWidth;
        }
        
        if( screenHeight > 480 && screenHeight < 667 ){
            NSLog(@"iPhone 5/5s");
            thirdPage.topPadding = 0;
            thirdPage.underIconPadding = 50;
            thirdPage.underTitlePadding = 225;
        } else if ( screenHeight > 480 && screenHeight < 736 ){
            NSLog(@"iPhone 6");
            thirdPage.topPadding = 0;
            thirdPage.underIconPadding = 65;
            thirdPage.underTitlePadding = 316;
        } else if ( screenHeight > 480 ){
            thirdPage.topPadding = 0;
            thirdPage.underIconPadding = 75;
            thirdPage.underTitlePadding = 375;
            NSLog(@"iPhone 6 Plus");
        } else {
            NSLog(@"iPhone 4/4s");
        }
    }
    
    OnboardingViewController *onboardingVC = [OnboardingViewController onboardWithBackgroundImage:nil contents:@[firstPage, secondPage, thirdPage]];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.fadePageControlOnLastPage = YES;
    onboardingVC.fadeSkipButtonOnLastPage = YES;
    
    // If you want to allow skipping the onboarding process, enable skipping and set a block to be executed
    // when the user hits the skip button.
    onboardingVC.allowSkipping = NO;
    onboardingVC.skipHandler = ^{
        [self handleOnboardingCompletion];
    };
    
    return onboardingVC;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - CoreData Stack

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"coreData"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

/**
 Returns the URL to the application's documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // copy the default store (with a pre-populated data) into our Documents folder
    //
    NSString *documentsStorePath =
    [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"Recipes.sqlite"];
    
    // if the expected store doesn't exist, copy the default store
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsStorePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"sqlite"];
        if (defaultStorePath) {
            [[NSFileManager defaultManager] copyItemAtPath:defaultStorePath toPath:documentsStorePath error:NULL];
        }
    }
    
    _persistentStoreCoordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    // add the default store to our coordinator
    NSError *error;
    NSURL *defaultStoreURL = [NSURL fileURLWithPath:documentsStorePath];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:defaultStoreURL
                                                         options:nil
                                                           error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible
         * The schema for the persistent store is incompatible with current managed object model
         Check the error message to determine what the actual problem was.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // setup and add the user's store to our coordinator
    NSURL *userStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"UserRecipes.sqlite"];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:userStoreURL
                                                         options:nil
                                                           error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible
         * The schema for the persistent store is incompatible with current managed object model
         Check the error message to determine what the actual problem was.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


@end
