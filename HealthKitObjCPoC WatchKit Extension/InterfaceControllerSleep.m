//
//  InterfaceControllerSleep.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 7/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "InterfaceControllerSleep.h"

@interface InterfaceControllerSleep ()

@property (nonatomic, unsafe_unretained) id<InterfaceControllerSleepDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *confirmMsgLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *proposedSleepLabel;
- (IBAction)denyButton;
- (IBAction)confirmButton;

@end

@implementation InterfaceControllerSleep

- (void)awakeWithContext:(id)context {
    
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.delegate = [context objectForKey:@"delegate"];
        
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    [super awakeWithContext:context];
    [self.proposedSleepLabel setText:[dateFormatter stringFromDate:[context objectForKey:@"time"]]];
    
    // Configure interface objects here.
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
    
    [self.delegate proposedSleepStartDecision:0];
    [self dismissController];
}

- (IBAction)confirmButton {
    
    [self.delegate proposedSleepStartDecision:1];
    [self dismissController];
}
@end



