//
//  SleepInputInterfaceController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/20/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepInputInterfaceController.h"
#import "Utility.h"

@interface SleepInputInterfaceController() <WKCrownDelegate>
@property (nonatomic, unsafe_unretained) id<SleepInputInterfaceControllerDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *timeLabel;

@property (nonatomic, readwrite) NSDate *testDate;
@property (nonatomic, readwrite) NSDate *testStartDate;
@property (nonatomic, readwrite) NSString *testFormatted;
@property (nonatomic, readwrite) NSDateFormatter *formatter;
@end

@implementation SleepInputInterfaceController



- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeSuccess];
    
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.delegate = [context objectForKey:@"delegate"];
        
    }
    
    self.crownSequencer.delegate = self;
    [self.crownSequencer focus];
    _testDate = [[NSDate alloc] init];
    _testStartDate = [NSDate date];
    _testFormatted = [[NSString alloc] init];
    _formatter = [Utility dateFormatterForTimeLabels];
    
    [_timeLabel setText:[_formatter stringFromDate:[context objectForKey:@"time"]]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}


- (void)crownDidRotate:(WKCrownSequencer *)crownSequencer rotationalDelta:(double)rotationalDelta {
    _testDate = [NSDate dateWithTimeInterval:rotationalDelta*60 sinceDate:_testDate];
    _testFormatted = [_formatter stringFromDate:_testDate];
    [self updateLabel];
}

- (void)updateLabel {
    [_timeLabel setText:_testFormatted];
}

- (IBAction)saveSleepTime {
    [self dismissController];
    [self.delegate proposedSleepStartDecision:0 SleepStartDate:_testDate];
}

@end
