//
//  SleepProgressRing.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 4/24/17.
//  Copyright © 2017 Sean Petykowski. All rights reserved.
//

#import "SleepProgressRing.h"
#import "Constants.h"
#import "ColorConstants.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@implementation SleepProgressRing

+ (NSArray *) WakeIndicatorImagesFadingIn:(BOOL)fadeIn ForWatchSize:(ImageSizeWatchSizeTypes)watchSize {
    double imageSize;
    if (watchSize == ImageSize42) {
        imageSize = kWakeIndicatorImageSize42;
    } else {
        imageSize = kWakeIndicatorImageSize38;
    }
    
    int imagesGenerated = 0;
    double imageAlpha = 0.0;
    UIImage *circleWakeIndicator;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    
    while (imagesGenerated < 10) {
        double imageSize = 65;
        
        // Initialize UIGraphicsImage
        CGSize size = CGSizeMake(imageSize, imageSize);
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0);
        CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(graphicsContext);
        CGContextSetBlendMode(graphicsContext, kCGBlendModeNormal);
        CGContextSetLineWidth(graphicsContext, 5.0);
        CGContextSetFillColorWithColor(graphicsContext, [[ColorConstants darkThemeWakeIndicatorColor] colorWithAlphaComponent:imageAlpha].CGColor);
        
        // Draw Circle
        CGRect circleRect = CGRectMake( 0, 0, size.width, size.height );
        circleRect = CGRectInset(circleRect, 5, 5);
        CGContextFillEllipseInRect(graphicsContext, circleRect);
        
        // Convert To Image
        CGImageRef wakeCGImage = CGBitmapContextCreateImage(graphicsContext);
        circleWakeIndicator = [UIImage imageWithCGImage:wakeCGImage scale:2.0 orientation:UIImageOrientationUp];
        UIGraphicsPopContext();
        UIGraphicsEndImageContext();
        
        // Prepare Array
        [images addObject:circleWakeIndicator];
        imagesGenerated++;
        imageAlpha += 0.1;
        
    }
    
    if (fadeIn) {
        return images;
    } else {
        return [[[images reverseObjectEnumerator] allObjects] mutableCopy];
    }
}

+ (UIImage *) SleepProgressRingImageForProgressInPercentage:(int)percentage ForWatchSize:(ImageSizeWatchSizeTypes)watchSize {
    
    double imageSize;
    if (watchSize == ImageSize42) {
        imageSize = kProgressRingImageSize42;
    } else {
        imageSize = kProgressRingImageSize38;
    }
    
    // Initialize UIGraphicsImage
    CGSize size = CGSizeMake(imageSize, imageSize);
    UIGraphicsBeginImageContextWithOptions(size, false, 2.0);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(graphicsContext);
    
    // Set Progress Ring Defaults
    CGPoint center = CGPointMake(imageSize/2, imageSize/2);
    CGFloat radius = MAX(imageSize, imageSize);
    CGFloat arcWidth = 6;
    
    // Background Ring Settings
    // Will create a full circle
    CGFloat backgroundStartAngle = degreesToRadians(0);
    CGFloat backgroundEndAngle = degreesToRadians(360);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:backgroundStartAngle endAngle:backgroundEndAngle clockwise:true];
    innerPath.lineWidth = arcWidth;
    innerPath.lineCapStyle = kCGLineCapRound;
    [[ColorConstants darkThemeSecondaryAccentColor] setStroke];
    [innerPath stroke];
    
    // Progress Ring Settings
    int percentageToDegrees = ((percentage * 360) / 100) + 270;
    CGFloat startAngle = degreesToRadians(270);
    CGFloat endAngle = degreesToRadians(percentageToDegrees);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:startAngle endAngle:endAngle clockwise:true];
    path.lineWidth = arcWidth;
    path.lineCapStyle = kCGLineCapRound;
    [[ColorConstants darkThemePrimaryAccentColor] setStroke];
    [path stroke];
    
    // If percentage is over 100 we will add a shadow
    if (percentage > 100) {
        // Recalcuate percentageToDegrees by first subtracting 100
        percentageToDegrees = (((percentage - 100) * 360) / 100) + 270;
        CGFloat shadowStartAngle = degreesToRadians(270);
        CGFloat shadowEndAngle = degreesToRadians(percentageToDegrees);
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:shadowStartAngle endAngle:shadowEndAngle clockwise:true];
        CGContextRef shadowContext = UIGraphicsGetCurrentContext();
        CGContextAddPath(shadowContext, shadowPath.CGPath);
        CGContextSetLineWidth(shadowContext, arcWidth);
        CGContextSetLineCap(shadowContext, kCGLineCapRound);
        CGContextSetShadowWithColor(shadowContext, CGSizeMake(0.5, 1.5), 2.0, [[UIColor blackColor]CGColor]);
        CGContextStrokePath(shadowContext);
        
        // Shadow appears at both ends, create a small path to cover top end
        CGFloat coverStartAngle = degreesToRadians(267);
        CGFloat coverEndAngle = degreesToRadians(271);
        UIBezierPath *coverPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:coverStartAngle endAngle:coverEndAngle clockwise:true];
        coverPath.lineWidth = arcWidth;
        coverPath.lineCapStyle = kCGLineCapRound;
        [[ColorConstants darkThemePrimaryAccentColor] setStroke];
        CGContextSetShadowWithColor(shadowContext, CGSizeMake(0, 0), 0, NULL);
        [coverPath stroke];
    }

    // Convert To Image
    CGImageRef ringCGImage = CGBitmapContextCreateImage(graphicsContext);
    UIImage *ringUIImage = [UIImage imageWithCGImage:ringCGImage scale:2.0 orientation:UIImageOrientationUp];
    UIGraphicsPopContext();
    UIGraphicsEndImageContext();
    
    return ringUIImage;
}

+ (UIImage *) SleepProgressRingAnalysisImageForProgressInPercentage:(int)percentage ForWatchSize:(ImageSizeWatchSizeTypes)watchSize {
    
    double imageSize;
    if (watchSize == ImageSize42) {
        imageSize = kProgressRingAnalysisImageSize42;
    } else {
        imageSize = kProgressRingAnalysisImageSize38;
    }
    
    // Initialize UIGraphicsImage
    CGSize size = CGSizeMake(imageSize, imageSize);
    UIGraphicsBeginImageContextWithOptions(size, false, 2.0);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(graphicsContext);
    
    // Set Progress Ring Defaults
    CGPoint center = CGPointMake(imageSize/2, imageSize/2);
    CGFloat radius = MAX(imageSize, imageSize);
    CGFloat arcWidth = 6;
    
    // Background Ring Settings
    // Will create a full circle
    CGFloat backgroundStartAngle = degreesToRadians(0);
    CGFloat backgroundEndAngle = degreesToRadians(360);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:backgroundStartAngle endAngle:backgroundEndAngle clockwise:true];
    innerPath.lineWidth = arcWidth;
    innerPath.lineCapStyle = kCGLineCapRound;
    [[ColorConstants darkThemeSecondaryAccentColor] setStroke];
    [innerPath stroke];
    
    // Progress Ring Settings
    int percentageToDegrees = ((percentage * 360) / 100) + 270;
    CGFloat startAngle = degreesToRadians(270);
    CGFloat endAngle = degreesToRadians(percentageToDegrees);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:startAngle endAngle:endAngle clockwise:true];
    path.lineWidth = arcWidth;
    path.lineCapStyle = kCGLineCapRound;
    [[ColorConstants darkThemePrimaryAccentColor] setStroke];
    [path stroke];
    
    // If percentage is over 100 we will add a shadow
    if (percentage > 100) {
        // Recalcuate percentageToDegrees by first subtracting 100
        percentageToDegrees = (((percentage - 100) * 360) / 100) + 270;
        CGFloat shadowStartAngle = degreesToRadians(270);
        CGFloat shadowEndAngle = degreesToRadians(percentageToDegrees);
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:shadowStartAngle endAngle:shadowEndAngle clockwise:true];
        CGContextRef shadowContext = UIGraphicsGetCurrentContext();
        CGContextAddPath(shadowContext, shadowPath.CGPath);
        CGContextSetLineWidth(shadowContext, arcWidth);
        CGContextSetLineCap(shadowContext, kCGLineCapRound);
        CGContextSetShadowWithColor(shadowContext, CGSizeMake(0.5, 1.5), 2.0, [[UIColor blackColor]CGColor]);
        CGContextStrokePath(shadowContext);
        
        // Shadow appears at both ends, create a small path to cover top end
        CGFloat coverStartAngle = degreesToRadians(267);
        CGFloat coverEndAngle = degreesToRadians(271);
        UIBezierPath *coverPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:coverStartAngle endAngle:coverEndAngle clockwise:true];
        coverPath.lineWidth = arcWidth;
        coverPath.lineCapStyle = kCGLineCapRound;
        [[ColorConstants darkThemePrimaryAccentColor] setStroke];
        CGContextSetShadowWithColor(shadowContext, CGSizeMake(0, 0), 0, NULL);
        [coverPath stroke];
    }
    
    // Convert To Image
    CGImageRef ringCGImage = CGBitmapContextCreateImage(graphicsContext);
    UIImage *ringUIImage = [UIImage imageWithCGImage:ringCGImage scale:2.0 orientation:UIImageOrientationUp];
    UIGraphicsPopContext();
    UIGraphicsEndImageContext();
    
    return ringUIImage;
}

+ (UIImage *) SleepProgressRingAnalysisAnimationForProgressInPercentage:(int)percentage ForWatchSize:(ImageSizeWatchSizeTypes)watchSize {
    
    NSMutableArray *arrayOfImages = [[NSMutableArray alloc] init];
    int imagesProcessed = 0;
    double imageSize;
    if (watchSize == ImageSize42) {
        imageSize = kProgressRingAnalysisImageSize42;
    } else {
        imageSize = kProgressRingAnalysisImageSize38;
    }
    
    while (imagesProcessed <= percentage) {
        // Initialize UIGraphicsImage
        CGSize size = CGSizeMake(imageSize, imageSize);
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0);
        CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(graphicsContext);
        
        // Set Progress Ring Defaults
        CGPoint center = CGPointMake(imageSize/2, imageSize/2);
        CGFloat radius = MAX(imageSize, imageSize);
        CGFloat arcWidth = 6;
        
        // Background Ring Settings
        // Will create a full circle
        CGFloat backgroundStartAngle = degreesToRadians(0);
        CGFloat backgroundEndAngle = degreesToRadians(360);
        UIBezierPath *innerPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:backgroundStartAngle endAngle:backgroundEndAngle clockwise:true];
        innerPath.lineWidth = arcWidth;
        innerPath.lineCapStyle = kCGLineCapRound;
        [[ColorConstants darkThemeSecondaryAccentColor] setStroke];
        [innerPath stroke];
        
        // Progress Ring Settings
        int percentageToDegrees = ((imagesProcessed * 360) / 100) + 270;
        CGFloat startAngle = degreesToRadians(270);
        CGFloat endAngle = degreesToRadians(percentageToDegrees);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:startAngle endAngle:endAngle clockwise:true];
        path.lineWidth = arcWidth;
        path.lineCapStyle = kCGLineCapRound;
        [[ColorConstants darkThemePrimaryAccentColor] setStroke];
        [path stroke];
        
        // If percentage is over 100 we will add a shadow
        if (imagesProcessed > 100) {
            // Recalcuate percentageToDegrees by first subtracting 100
            percentageToDegrees = (((imagesProcessed - 100) * 360) / 100) + 270;
            CGFloat shadowStartAngle = degreesToRadians(270);
            CGFloat shadowEndAngle = degreesToRadians(percentageToDegrees);
            UIBezierPath *shadowPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:shadowStartAngle endAngle:shadowEndAngle clockwise:true];
            CGContextRef shadowContext = UIGraphicsGetCurrentContext();
            CGContextAddPath(shadowContext, shadowPath.CGPath);
            CGContextSetLineWidth(shadowContext, arcWidth);
            CGContextSetLineCap(shadowContext, kCGLineCapRound);
            CGContextSetShadowWithColor(shadowContext, CGSizeMake(0.5, 1.5), 2.0, [[UIColor blackColor]CGColor]);
            CGContextStrokePath(shadowContext);
            
            // Shadow appears at both ends, create a small path to cover top end
            CGFloat coverStartAngle = degreesToRadians(267);
            CGFloat coverEndAngle = degreesToRadians(271);
            UIBezierPath *coverPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius/2 - arcWidth/2 startAngle:coverStartAngle endAngle:coverEndAngle clockwise:true];
            coverPath.lineWidth = arcWidth;
            coverPath.lineCapStyle = kCGLineCapRound;
            [[ColorConstants darkThemePrimaryAccentColor] setStroke];
            CGContextSetShadowWithColor(shadowContext, CGSizeMake(0, 0), 0, NULL);
            [coverPath stroke];
        }
        
        // Convert To Image
        CGImageRef ringCGImage = CGBitmapContextCreateImage(graphicsContext);
        UIImage *ringUIImage = [UIImage imageWithCGImage:ringCGImage scale:2.0 orientation:UIImageOrientationUp];
        UIGraphicsPopContext();
        UIGraphicsEndImageContext();
        
        [arrayOfImages addObject:ringUIImage];
        
        imagesProcessed++;
        NSLog(@"Made it here");
    }
    UIImage *animatedImage = [UIImage animatedImageWithImages:arrayOfImages duration:1];
    
    return animatedImage;
}

@end
