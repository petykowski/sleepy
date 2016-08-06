//
//  dataController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/6/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface dataController : NSObject

@property (strong) NSManagedObjectContext *managedObjectContext;

- (void)initializeCoreData;

@end
