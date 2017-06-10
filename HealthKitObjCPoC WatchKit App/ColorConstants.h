//
//  ColorConstants.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 11/24/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorConstants : UIColor
#pragma mark System Wide Colors
/**
 * @brief Returns a dark black color. Used as a primary background color.
 */
+ (UIColor *)darkThemePrimaryBackgroundColor;

/**
 * @brief Returns a light black color. Used as a secondary background color.
 */
+ (UIColor *)darkThemeSecondaryBackgroundColor;
+ (UIColor *)darkThemeLineSeperator;

/**
 * @brief Returns a white color. Used as a primary text color.
 */
+ (UIColor *)darkThemePrimaryTextColor;

/**
 * @brief Returns a light grey color. Used as a secondary text color.
 */
+ (UIColor *)darkThemeSecondaryTextColor;

/**
 * @brief Returns a bright purple. Used as an accent color or featured color.
 */
+ (UIColor *)darkThemePrimaryAccentColor;

/**
 * @brief Returns a dark purple. Used as background for progress ring.
 */
+ (UIColor *)darkThemeSecondaryAccentColor;

/**
 * @brief Returns a bright purple. Used as an accent color or featured color.
 */
+ (UIColor *)darkThemeChartGridLineColor;

/**
 * @brief Returns a bright yellow. Used as a featured color for the wake indicator icon.
 */
+ (UIColor *)darkThemeWakeIndicatorColor;

@end
