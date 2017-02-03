//
//  SleepStatistic.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/25/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SleepStatistic : NSObject

- (id)initWithDouble:(double)result;

@property (nonatomic, strong) NSString *name;
@property (nonatomic) double result;
@property (nonatomic, strong) NSString *stringResult;

@end
