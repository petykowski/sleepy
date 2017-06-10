//
//  SleepProgressRing.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 4/24/17.
//  Copyright © 2017 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SleepProgressRing : NSObject

typedef NS_ENUM(NSInteger, ProgressRingSizeTypes) {
    RingImageSize38,
    RingImageSize42
};

/**
 * @brief Returns a UIImage of a progress ring indicating the current sleep duration.
 */
+ (UIImage *) SleepProgressRingImageForProgressInPercentage:(int)percentage ForWatchSize:(ProgressRingSizeTypes)watchSize;

/**
 * @brief Returns a NSArrary containing a series of images used for the wake indicator animation.
 */
+ (NSArray *) WakeIndicatorImagesFadingIn:(BOOL)fadeIn ForWatchSize:(ProgressRingSizeTypes)watchSize;

@end
