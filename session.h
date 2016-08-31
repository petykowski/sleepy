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
@property (nonatomic, strong) NSData *inBed;
@property (nonatomic, strong) NSData *sleep;
@property (nonatomic, strong) NSData *wake;
@property (nonatomic, strong) NSData *outBed;



@end
