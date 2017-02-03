//
//  SleepStatistic.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/25/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepStatistic.h"

@implementation SleepStatistic

- (id)init {
    self = [super init];
    if (self) {
        _name = [[NSString alloc] init];
        _stringResult = [[NSString alloc] init];
    }
    return self;
}

- (id)initWithDouble:(double)result {
    self = [super init];
    if (self) {
        _name = [[NSString alloc] init];
        _stringResult = [[NSString alloc] init];
        _result = result;
    }
    return self;
}


@end
