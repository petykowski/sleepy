//
//  SleepSession.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepSession.h"

@implementation SleepSession

- (id)initWithSleepSession:(NSDictionary *)sleepSession {
    self = [super init];
    if (self) {
        NSNumber *numberToBool = [sleepSession objectForKey:@"isSleepSessionInProgress"];
        _isSleepSessionInProgress = [numberToBool boolValue];
        _inBed = [sleepSession objectForKey:@"inBed"];
        _sleep = [sleepSession objectForKey:@"sleep"];
        _wake = [sleepSession objectForKey:@"wake"];
        _outBed = [sleepSession objectForKey:@"outBed"];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _name = [[NSString alloc] init];
        _inBed = [[NSMutableArray alloc] init];
        _sleep = [[NSMutableArray alloc] init];
        _wake = [[NSMutableArray alloc] init];
        _outBed = [[NSMutableArray alloc] init];
    }
    return self;

}

@end
