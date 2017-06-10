//
//  ColorConstants.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 11/24/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "ColorConstants.h"

@implementation ColorConstants

+ (UIColor *)darkThemePrimaryBackgroundColor {
    return [UIColor colorWithRed:0.07058823529 green:0.07058823529 blue:0.07058823529 alpha:1.0];
}

+ (UIColor *)darkThemeSecondaryBackgroundColor {
    return [UIColor colorWithRed:0.1137254902 green:0.1137254902 blue:0.1137254902 alpha:1.0];
}

+ (UIColor *)darkThemeLineSeperator {
    return [UIColor colorWithRed:0.2 green:0.2 blue:0.2078431373 alpha:1.0];
}

+ (UIColor *)darkThemePrimaryTextColor {
    return [UIColor whiteColor];
}

+ (UIColor *)darkThemeSecondaryTextColor {
    return [UIColor lightGrayColor];
}

+ (UIColor *)darkThemePrimaryAccentColor {
    return [UIColor colorWithRed:0.3725490196 green:0.3058823529 blue:0.7176470588 alpha:1.0];
}

+ (UIColor *)darkThemeSecondaryAccentColor {
    return [UIColor colorWithRed:0.1450980392 green:0.137254902 blue:0.1882352941 alpha:1.0];
}

+ (UIColor *)darkThemeChartGridLineColor {
    return [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
}

+ (UIColor *)darkThemeWakeIndicatorColor {
    return [UIColor colorWithRed:0.937254902 green:0.7254901961 blue:0.1490196078 alpha:1.0];
}

@end
