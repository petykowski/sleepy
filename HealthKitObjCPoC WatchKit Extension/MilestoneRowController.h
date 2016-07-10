//
//  MilestoneRowController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface MilestoneRowController : NSObject

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *milestoneLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *milestoneTimeLabel;

@end
