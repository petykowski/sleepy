//
//  SleepAnalysisWKInterfaceController.m
//  HealthKitObjCPoC WatchKit Extension
//
//  Created by Sean Petykowski on 7/2/17.
//  Copyright © 2017 Sean Petykowski. All rights reserved.
//

#import "SleepAnalysisWKInterfaceController.h"
#import "SleepProgressRing.h"

@interface SleepAnalysisWKInterfaceController()

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *heartRateLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceImage *progressRingImage;

@end

@implementation SleepAnalysisWKInterfaceController

- (instancetype)init {
    self = [super init];
    [self updateWatchRing];
    return self;
}

-(void)updateWatchRing {
    [_progressRingImage setImage:[SleepProgressRing SleepProgressRingAnalysisAnimationForProgressInPercentage:50 ForWatchSize:ImageSize42]];
    [_progressRingImage startAnimating];
    [self performSelector:@selector(stopImage) withObject:nil afterDelay:1];
    
}

-(void)stopImage {
    [_progressRingImage stopAnimating];
}


@end
