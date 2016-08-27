//
//  AppDelegate.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@end

