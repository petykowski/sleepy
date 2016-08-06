//
//  session.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/6/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface session : NSManagedObject

@property (nonatomic, strong) NSDate *inBedStart;

@end
