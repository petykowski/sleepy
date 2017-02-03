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
extern NSString *const kOnboardingFourthPageTitle;
extern NSString *const kOnboardingFourthPageBody;
extern NSString *const kOnboardingFourthPageButton;

#pragma mark Empty Data Set Screen
extern NSString *const kNoSessionsToDisplayTitle;
extern NSString *const kNoSessionsToDisplayBody;
extern NSString *const kNoStatisticsToDisplayTitle;
extern NSString *const kNoStatisticsToDisplayBody;

#pragma mark - Local User Notifications
extern NSString *const kEndSleepSessionCategoryIdentifier;
extern NSString *const kSnoozeActionIdentifier;
extern NSString *const kEndSleepSessionActionIdentifier;
extern NSString *const kRemindUserToEndSleepSessionNotificationTitle;
extern NSString *const kRemindUserToEndSleepSessionNotificationSubtitle;
extern NSString *const kRemindUserToEndSleepSessionNotificationBody;
extern double const kRemindUserToEndSleepSessionTimeIntervalInSeconds;

#pragma mark Numbers
extern double const kDigitalCrownScrollMultiplier;
extern double const kDefaultFontSizeTimeLabel;
extern double const kRemoveDeferredOptionTimer;
extern double const kScaleCountLowerLimit;
extern double const kScaleCountUpperLimit;

@end
