//
//  SleepInputInterfaceController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/20/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepInputInterfaceController.h"
#import "Utility.h"
#import "Constants.h"

@interface SleepInputInterfaceController() <WKCrownDelegate>

@property (nonatomic, unsafe_unretained) id<SleepInputInterfaceControllerDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *timeInputLabel;
@property (nonatomic, readwrite) NSDate *inputDate;
@property (nonatomic, readwrite) NSDate *originalSleepStart;
@property (nonatomic, readwrite) NSDate *maxSleepStart;
@property (nonatomic, readwrite) NSString *formattedTimeForTimeInputLabel;
@property (nonatomic, readwrite) NSDateFormatter *timeFormatterForTimeInputLabel;

@property (nonatomic, readwrite) double scaleOfTimeLabel;
@property (nonatomic, readwrite) double scaleCount;

@end

@implementation SleepInputInterfaceController

- (instancetype)init {
    self = [super init];
    
    [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeSuccess];
    self.crownSequencer.delegate = self;
    
    _formattedTimeForTimeInputLabel = [[NSString alloc] init];
    _timeFormatterForTimeInputLabel = [Utility dateFormatterForTimeLabels];
    _scaleOfTimeLabel = kDefaultFontSizeTimeLabel;
    _scaleCount = kScaleCountLowerLimit;
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.delegate = [context objectForKey:@"delegate"];
        _inputDate = [context objectForKey:@"time"];
        _originalSleepStart = [context objectForKey:@"time"];
        _maxSleepStart = [context objectForKey:@"maxSleepStart"];
    }
    [self updateLabel];
}

- (void)willActivate {
    [super willActivate];
    [self.crownSequencer focus];
}

- (void)crownDidRotate:(WKCrownSequencer *)crownSequencer rotationalDelta:(double)rotationalDelta {
    NSLog(@"[DEBUG] rotational delta %f", rotationalDelta);
    NSLog(@"[DEBUG] _maxSleepStart %@", _maxSleepStart);
    NSLog(@"[DEBUG] _inputDate %@", _inputDate);
    NSLog(@"[DEBUG] _originalSleepStart %@", _originalSleepStart);
    if (_inputDate == _originalSleepStart && rotationalDelta <= 0.000001 && _scaleCount != kScaleCountUpperLimit) {
        _inputDate = _originalSleepStart;
        _scaleOfTimeLabel = _scaleOfTimeLabel - .5;
        _scaleCount = _scaleCount + 1;
        if (_scaleCount == kScaleCountUpperLimit) {
            [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeStart];
        }
        [self updateLabel];
    } else if (_inputDate == _maxSleepStart && rotationalDelta >= -0.000001 && _scaleCount != kScaleCountUpperLimit) {
        _inputDate = _maxSleepStart;
        _scaleOfTimeLabel = _scaleOfTimeLabel - .5;
        _scaleCount = _scaleCount + 1;
        if (_scaleCount == kScaleCountUpperLimit) {
            [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeStart];
        }
        [self updateLabel];
    } else if ([Utility compare:_inputDate isLaterThanOrEqualTo:_originalSleepStart]){
        _inputDate = [NSDate dateWithTimeInterval:rotationalDelta * kDigitalCrownScrollMultiplier sinceDate:_inputDate];
        _scaleOfTimeLabel = kDefaultFontSizeTimeLabel;
        if ([Utility compare:_inputDate isEarlierThan:_originalSleepStart]) {
            _inputDate = _originalSleepStart;
        } else if ([Utility compare:_inputDate isLaterThanOrEqualTo:_maxSleepStart]){
            _inputDate = _maxSleepStart;
        }
        [self updateLabel];
    }
}

- (void) crownDidBecomeIdle:(WKCrownSequencer *)crownSequencer {
    _scaleOfTimeLabel = kDefaultFontSizeTimeLabel;
    _scaleCount = kScaleCountLowerLimit;
    [self updateLabel];
}

- (void)updateLabel {
    _formattedTimeForTimeInputLabel = [_timeFormatterForTimeInputLabel stringFromDate:_inputDate];
    NSAttributedString *inputDisplayString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", _formattedTimeForTimeInputLabel] attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:_scaleOfTimeLabel]}];
    [_timeInputLabel setAttributedText:inputDisplayString];
}

- (IBAction)saveSleepTime {
    [self.crownSequencer resignFocus];
    [self dismissController];
    [self.delegate proposedSleepStartDecision:0 SleepStartDate:_inputDate];
}

@end
