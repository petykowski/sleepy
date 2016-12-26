//
//  Constants.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

#pragma mark System Files
extern NSString *const kSleepSessionFileNameForWatch;
extern NSString *const kLogOutputFileName;

#pragma mark User Onboarding
extern NSString *const kUserHasOnboardedKey;
extern NSString *const kOnboardingFirstPageBody;
extern NSString *const kOnboardingSecondPageTitle;
extern NSString *const kOnboardingSecondPageBody;
extern NSString *const kOnboardingSecondPageButton;
extern NSString *const kOnboardingThirdPageTitle;
extern NSString *const kOnboardingThirdPageBody;
extern NSString *const kOnboardingThirdPageButton;

#pragma mark Empty Data Set Screen
extern NSString *const kNoSessionsToDisplayTitle;
extern NSString *const kNoSessionsToDisplayBody;
extern NSString *const kNoStatisticsToDisplayTitle;
extern NSString *const kNoStatisticsToDisplayBody;

#pragma mark Numbers
extern double const kDigitalCrownScrollMultiplier;
extern double const kDefaultFontSizeTimeLabel;
extern double const kScaleCountLowerLimit;
extern double const kScaleCountUpperLimit;

@end
