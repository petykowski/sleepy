//
//  Utility.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/12/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (NSDateFormatter*)dateFormatterForTimeLabels;
+ (NSDictionary*)contentsOfHealthPlist;
+ (NSDateFormatter*)dateFormatterForCellLabel;
+ (NSMutableArray*)convertAndPopulateSleepSessionDataForMilestone:(NSDictionary*)sleepSessionData;

@end
