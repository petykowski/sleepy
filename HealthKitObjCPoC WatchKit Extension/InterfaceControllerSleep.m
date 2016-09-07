//
//  InterfaceControllerSleep.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "InterfaceControllerSleep.h"
#import "Utility.h"

@interface InterfaceControllerSleep ()

@property (nonatomic, unsafe_unretained) id<InterfaceControllerSleepDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *confirmMsgLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *proposedSleepLabel;
- (IBAction)denyButton;
- (IBAction)confirmButton;

@end

@implementation InterfaceControllerSleep

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeSuccess];
    
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.delegate = [context objectForKey:@"delegate"];
        
    }
    
    NSDateFormatter *dateFormatter = [Utility dateFormatterForTimeLabels];
    
    [self.proposedSleepLabel setText:[dateFormatter stringFromDate:[context objectForKey:@"time"]]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)denyButton {
    [self dismissController];
    [self.delegate proposedSleepStartDecision:0];
}

- (IBAction)confirmButton {
    [self dismissController];
    [self.delegate proposedSleepStartDecision:1];
}
@end



