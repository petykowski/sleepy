//
//  Utility.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/12/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+(NSDateFormatter*)dateFormatterForTimeLabels {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    return dateFormatter;
    
}

+(NSDateFormatter*)dateFormatterForCellLabel {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MMMM d"];
    return dateFormatter;
    
}

+(NSDictionary*)contentsOfHealthPlist {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Health.plist"];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    return plistDictionary;
}

+(NSMutableArray*)convertAndPopulateSleepSessionDataForMilestone: (NSDictionary*)sleepSessionData {
    NSMutableArray *convertedData = [[NSMutableArray alloc] init];
    NSArray *inBed = [sleepSessionData objectForKey:@"inBedArray"];
    
        NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
        for (int i = 0; i < inBed.count; i++) {
            [convertedData addObject:[[sleepSessionData objectForKey:@"inBedArray"] objectAtIndex:i]];
            [convertedData addObject:[[sleepSessionData objectForKey:@"sleepArray"] objectAtIndex:i]];
            [convertedData addObject:[[sleepSessionData objectForKey:@"wakeArray"] objectAtIndex:i]];
            [convertedData addObject:[[sleepSessionData objectForKey:@"outBedArray"] objectAtIndex:i]];
        }
        
        for (int i = 0; i < convertedData.count; i++) {
            [convertedData replaceObjectAtIndex:i withObject:[dateFormatter stringFromDate:convertedData[i]]];
        }

    return convertedData;
}

@end
