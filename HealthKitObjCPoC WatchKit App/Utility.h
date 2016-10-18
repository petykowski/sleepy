//
//  Utility.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/12/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SleepSession.h"
#import "session.h"

@interface Utility : NSObject

+ (NSDateFormatter*)dateFormatterForTimeLabels;

/**
 * @brief Returns a label ready string to display the time duration of the number of seconds provided
 * @param Integer total number of seconds
 * @return 00h 00m 00s
*/
+ (NSString *)timeFormatter:(int)totalSeconds;
+ (NSString*)pathToSleepSessionDataFile;
+ (SleepSession*)contentsOfCurrentSleepSession;
+ (SleepSession*)contentsOfPreviousSleepSession;
+ (NSDictionary*)contentsOfHealthPlist;
+ (NSDateFormatter*)dateFormatterForCellLabel;
+ (NSMutableArray*)convertAndPopulateSleepSessionDataForMilestone:(NSDictionary*)sleepSessionData;
+ (NSMutableArray*)convertAndPopulatePreviousSleepSessionDataForMilestone:(SleepSession*)previousSleepSession;
+ (NSDictionary*)convertManagedObjectSessionToDictionaryForDetailView: (session *)sleepSession;
+ (SleepSession*)convertManagedObjectSessionToSleepSessionForDetailView: (session *)sleepSession;
+ (NSMutableArray *)convertManagedObjectsToSleepSessions: (NSArray *)sleepArray;
@end
