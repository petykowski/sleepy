//
//  Constants.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/9/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//


#import "Constants.h"

@implementation Constants

#pragma mark - System Files
NSString *const kSleepSessionFileNameForWatch = @"SavedSleepSession.plist";
NSString *const kLogOutputFileName = @"logs.txt";


#pragma mark - User Onboarding Strings
// user_has_onboarded: inital deployment of user onboarding.
// user_has_onboarded_v1: added push notifications support to user onboarding.
NSString *const kUserHasOnboardedKey = @"user_has_onboarded_v1";
NSString *const kOnboardingFirstPageBody = @"Sleepy is a sleep tracking app that helps users make sense of their sleep patterns.";
NSString *const kOnboardingSecondPageTitle = @"Integrate with HealthKit";
NSString *const kOnboardingSecondPageBody = @"Allowing access to HealthKit allows Sleepy to determine when you've fallen asleep and build sleep trends.";
NSString *const kOnboardingSecondPageButton = @"Enable HealthKit Access";
NSString *const kOnboardingThirdPageTitle = @"Let Sleepy Wake You";
NSString *const kOnboardingThirdPageBody = @"Sleepy can remind you to get out of bed, even after you've snoozed a few times.";
NSString *const kOnboardingThirdPageButton = @"Enable Notifications";
NSString *const kOnboardingFourthPageTitle = @"Start Sleeping Smarter";
NSString *const kOnboardingFourthPageBody = @"When using the Sleepy watch app, 3D Touch to begin a new sleep session, and then again to wake.";
NSString *const kOnboardingFourthPageButton = @"Get Started";


#pragma mark - Empty Data Set Screen
NSString *const kNoSessionsToDisplayTitle = @"You Don't Have Any Recent Sleep Sessions";
NSString *const kNoSessionsToDisplayBody = @"Complete a sleep session on Apple Watch and check back here in the morning!";
NSString *const kNoStatisticsToDisplayTitle = @"No Statistics Available";
NSString *const kNoStatisticsToDisplayBody = @"Statistics are available after 7 sleep sessions.";
NSString *const kNoHeartRateDataToDisplayTitle = @"No Heart Rate Data Available";
NSString *const kNoHeartRateDataToDisplayBody = @"Allow access to heart rate data in the Health app.";

#pragma mark - Local User Notifications
NSString *const kEndSleepSessionCategoryIdentifier = @"END_SLEEP_SESSION_CATEGORY";
NSString *const kSnoozeActionIdentifier = @"SNOOZE_ACTION";
NSString *const kEndSleepSessionActionIdentifier = @"END_SLEEP_SESSION_ACTION";
NSString *const kRemindUserToEndSleepSessionNotificationTitle = @"Still Sleepy?";
NSString *const kRemindUserToEndSleepSessionNotificationSubtitle = @"Active Sleep Session";
NSString *const kRemindUserToEndSleepSessionNotificationBody = @"You've woken up but haven't ended the sleep session. Would you like to end your sleep session?";
double const kRemindUserToEndSleepSessionTimeIntervalInSeconds = 300;


#pragma mark - Numbers
double const kDigitalCrownScrollMultiplier = 500;
double const kDefaultFontSizeTimeLabel = 30;
double const kRemoveDeferredOptionTimer = 7200;
double const kScaleCountLowerLimit = 0;
double const kScaleCountUpperLimit = 11;
double const kProgressRingImageSize38 = 92;
double const kProgressRingImageSize42 = 110;
double const kWakeIndicatorImageSize38 = 55;
double const kWakeIndicatorImageSize42 = 65;

@end
