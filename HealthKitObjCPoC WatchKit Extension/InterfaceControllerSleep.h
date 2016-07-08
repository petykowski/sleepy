//
//  InterfaceControllerSleep.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceControllerSleep : WKInterfaceController


@end


@protocol InterfaceControllerSleepDelegate <NSObject>

- (void)proposedSleepStartDecision:(int)buttonValue;

@end
