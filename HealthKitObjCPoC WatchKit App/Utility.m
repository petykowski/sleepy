//
//  Utility.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/12/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "Utility.h"
#import "Constants.h"
#import "SleepSession.h"
#import "session.h"

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

+(NSString*)pathToSleepSessionDataFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:sleepSessionFileNameForWatch];
    
    return filePath;
}

+(SleepSession*)contentsOfCurrentSleepSession {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:sleepSessionFileNameForWatch];
    
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableDictionary *currentSleepSessionDictionary = [[NSMutableDictionary alloc] initWithDictionary:[sleepSessionFile objectForKey:@"Current Sleep Session"]];
    
    SleepSession *currentSleepSession = [[SleepSession alloc] initWithSleepSession:currentSleepSessionDictionary];
    
    return currentSleepSession;
}

+(SleepSession*)contentsOfPreviousSleepSession {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:sleepSessionFileNameForWatch];
    
    NSMutableDictionary *sleepSessionFile = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableDictionary *previousleepSessionDictionary = [[NSMutableDictionary alloc] initWithDictionary:[sleepSessionFile objectForKey:@"Previous Sleep Session"]];
    
    SleepSession *previousSleepSession = [[SleepSession alloc] initWithSleepSession:previousleepSessionDictionary];
    
    return previousSleepSession;
}

+(NSDictionary*)contentsOfHealthPlist {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:sleepSessionFileNameForWatch];
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    return plistDictionary;
}

+(NSMutableArray*)convertAndPopulatePreviousSleepSessionDataForMilestone: (SleepSession*)previousSleepSession {
    NSMutableArray *convertedData = [[NSMutableArray alloc] init];
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    for (int i = 0; i < previousSleepSession.inBed.count; i++) {
        [convertedData addObject:[previousSleepSession.inBed objectAtIndex:i]];
        [convertedData addObject:[previousSleepSession.sleep objectAtIndex:i]];
        [convertedData addObject:[previousSleepSession.wake objectAtIndex:i]];
        [convertedData addObject:[previousSleepSession.outBed objectAtIndex:i]];
    }
    
    for (int i = 0; i < convertedData.count; i++) {
        [convertedData replaceObjectAtIndex:i withObject:[dateFormatter stringFromDate:convertedData[i]]];
    }
    return convertedData;
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

+(NSDictionary*)convertManagedObjectSessionToDictionaryForDetailView: (session *)sleepSession {
    NSMutableDictionary *convertedDict = [[NSMutableDictionary alloc] init];
    NSDateFormatter *dateTitle = [Utility dateFormatterForCellLabel];
    
    [convertedDict setObject:[dateTitle stringFromDate:sleepSession.creationDate] forKey:@"creationDate"];
    [convertedDict setObject:[NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.inBed] forKey:@"inBedArray"];
    [convertedDict setObject:[NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.sleep] forKey:@"sleepArray"];
    [convertedDict setObject:[NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.wake] forKey:@"wakeArray"];
    [convertedDict setObject:[NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.outBed] forKey:@"outBedArray"];
    
    return convertedDict;
}

+(SleepSession*)convertManagedObjectSessionToSleepSessionForDetailView: (session *)sleepSession {
    NSDateFormatter *dateTitle = [Utility dateFormatterForCellLabel];
    SleepSession *detailSleepSession = [[SleepSession alloc] init];
    
    detailSleepSession.name = [dateTitle stringFromDate:sleepSession.creationDate];
    detailSleepSession.inBed = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.inBed];
    detailSleepSession.sleep = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.sleep];
    detailSleepSession.wake = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.wake];
    detailSleepSession.outBed = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.outBed];
    
    return detailSleepSession;
}

+(NSMutableArray *)convertManagedObjectsToSleepSessions: (NSArray *)sleepArray {
    NSMutableArray *convertedSleepSessions = [[NSMutableArray alloc] init];
    for (int x = 0; x < sleepArray.count; x++) {
        SleepSession *sleepSession = [[SleepSession alloc] init];
        sleepSession = [self convertManagedObjectSessionToSleepSessionForDetailView:[sleepArray objectAtIndex:x]];
        [convertedSleepSessions addObject:sleepSession];
    }
    
    return convertedSleepSessions;
}

@end
