//
//  session.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/6/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "session.h"

@implementation session

@dynamic name;
@dynamic isCurrentSession;
@dynamic creationDate;
@dynamic inBed;
@dynamic sleep;
@dynamic wake;
@dynamic outBed;

-(NSString *)sectionByMonthAndYearUsingCreationDate{
    NSDateComponents *components;
    components = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self.creationDate];
    
    NSInteger month = [components month];
    NSInteger year = [components year];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    NSString *result = [NSString stringWithFormat:@"%@ %ld", [[formatter monthSymbols] objectAtIndex:(month-1)], (long)year];
    return result;
}

@end
