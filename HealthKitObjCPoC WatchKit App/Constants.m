//
//  Constants.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "Constants.h"

@implementation Constants

#pragma System Files
NSString *const kSleepSessionFileNameForWatch = @"SavedSleepSession.plist";

#pragma User Onboarding Strings
NSString *const kUserHasOnboardedKey = @"user_has_onboarded";
NSString *const kOnboardingFirstPageBody = @"Sleepy is a sleep tracking app that helps users make sense of their sleep patterns.";
NSString *const kOnboardingSecondPageTitle = @"Integrate with HealthKit";
NSString *const kOnboardingSecondPageBody = @"Allowing access to HealthKit allows Sleepy to determine when you've fallen asleep and build sleep trends.";
NSString *const kOnboardingSecondPageButton = @"Enable HealthKit Access";
NSString *const kOnboardingThirdPageTitle = @"Start Sleeping Smarter";
NSString *const kOnboardingThirdPageBody = @"When using the Sleepy watch app, 3D Touch to begin a new sleep session, and then again to wake.";
NSString *const kOnboardingThirdPageButton = @"Get Started";

#pragma Empty Data Set Screen
NSString *const kNoSessionsToDisplayTitle = @"You Don't Have Any Recent Sleep Sessions";
NSString *const kNoSessionsToDisplayBody = @"Complete a sleep session on Apple Watch and check back here in the morning!";
NSString *const kNoStatisticsToDisplayTitle = @"No Statistics Available";
NSString *const kNoStatisticsToDisplayBody = @"Statistics are available after 7 sleep sessions.";

#pragma Numbers
double const kDigitalCrownScrollMultiplier = 500;
double const kDefaultFontSizeTimeLabel = 30;
double const kScaleCountLowerLimit = 0;
double const kScaleCountUpperLimit = 11;

@end
