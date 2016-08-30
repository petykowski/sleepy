//
//  session.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/6/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface session : NSManagedObject

@property (nonatomic, strong) NSString *name;
@property Boolean isCurrentSession;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *awakeStart;
@property (nonatomic, strong) NSDate *awakeStop;
@property (nonatomic, strong) NSDate *inBedStart;
@property (nonatomic, strong) NSDate *inBedStop;
@property (nonatomic, strong) NSDate *sleepStart;
@property (nonatomic, strong) NSDate *sleepStartProposed;
@property (nonatomic, strong) NSDate *sleepStop;


@end
