//
//  SleepSession.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SleepSession : NSObject

@property (nonatomic) BOOL isSleepSessionInProgress;
/** This property knows my name. */
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *inBed;
@property (nonatomic, strong) NSMutableArray *sleep;
@property (nonatomic, strong) NSMutableArray *wake;
@property (nonatomic, strong) NSMutableArray *outBed;

- (id)initWithSleepSession:(NSDictionary *)sleepSession;

@end
