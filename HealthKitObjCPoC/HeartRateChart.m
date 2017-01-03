//
//  HeartRateChart.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 11/6/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "HeartRateChart.h"

@implementation HeartRateChart

@synthesize datesArray = _datesArray;

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    NSLog(@"[DEBUG] 1. Contents of Date Array initWithFrame %@", _datesArray);
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    self.backgroundColor = [UIColor colorWithRed:0.1137254902 green:0.1137254902 blue:0.1137254902 alpha:1.0];
    [self setDefaultParameters];
}

- (void)setDefaultParameters {
}

- (void)setChartData {
    NSLog(@"[DEBUG] Set Chart Data Called");
    [self setNeedsLayout];
}

- (void)drawRect:(CGRect)rect {
    
    CGRect titleSection = CGRectMake(-2, 0, self.frame.size.width + 4, 35);
    CGRect xAxisSection = CGRectMake(-2, 240, self.frame.size.width + 4, 39.5);
    CGRect yAxisSection = CGRectMake(-2, 0, 52, self.frame.size.height + 4);
    
    CGContextRef greenContext = UIGraphicsGetCurrentContext();

    UIColor *separatorColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2078431373 alpha:1.0];
    UIColor *backgroundColor = [UIColor colorWithRed:0.1137254902 green:0.1137254902 blue:0.1137254902 alpha:1.0];
    
    CGContextSetStrokeColorWithColor(greenContext, separatorColor.CGColor);
    CGContextSetFillColorWithColor(greenContext, backgroundColor.CGColor);
    
    CGContextStrokeRectWithWidth(greenContext, titleSection, 1.0);
    CGContextStrokeRectWithWidth(greenContext, xAxisSection, 1.0);
    CGContextStrokeRectWithWidth(greenContext, yAxisSection, 1.0);
    
    CGContextFillRect(greenContext, titleSection);
    CGContextFillRect(greenContext, xAxisSection);
    
    
    UILabel *chartLabel = [[UILabel alloc] initWithFrame:titleSection];
    [chartLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    [chartLabel setTextAlignment:NSTextAlignmentCenter];
    [chartLabel setFont:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]];
    [chartLabel setText:@"Heart Rate"];
    [self addSubview:chartLabel];
    
    int xoffset = (xAxisSection.size.width - 20) / 6;
    int yoffset = 205 / 4;
    int maxNumberOfLabels = 6;
    
    NSArray *textArray = @[@"10 PM", @"11 PM", @"12 PM", @"1 AM", @"2 AM", @"3 AM", @"4 AM"];
    
    NSMutableArray *finalArray = [[NSMutableArray alloc] init];
    
    if (textArray.count < maxNumberOfLabels) {
        
        xoffset = (xAxisSection.size.width - 20) / textArray.count;
        maxNumberOfLabels = (int)textArray.count;
        [finalArray addObjectsFromArray:textArray];
        
    } else if (textArray.count >= maxNumberOfLabels) {
        
        for (int x = 0; x < maxNumberOfLabels; x++) {
            
            if (x == 0) {
                [finalArray addObject:[textArray firstObject]];
            } else if (x == maxNumberOfLabels -1) {
                [finalArray addObject:[textArray lastObject]];
            } else {
                [finalArray addObject:textArray[x]];
            }
        }
    }
    NSLog(@"[DEBUG] final Array = %@", finalArray);
    for (int x = 0; x < maxNumberOfLabels; x++) {
        /*
        NSInteger q = (int)_datesArray.count / 5;
        NSInteger itemIndex = q * x;
        
        if(itemIndex >= _datesArray.count) {
            itemIndex = _datesArray.count - 1;
        }
        */
        
        
        NSString *text = [finalArray objectAtIndex:x];
        float width = [text boundingRectWithSize:rect.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:nil
                                         context:nil].size.width;
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(35 + (xoffset * x), xAxisSection.origin.y, width, xAxisSection.size.height)];
        [textLabel setTextAlignment:NSTextAlignmentRight];
        [textLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
        [textLabel setFont:[UIFont systemFontOfSize:10 weight:UIFontWeightRegular]];
        [textLabel setText:[NSString stringWithFormat:@"%@", text]];
        [self addSubview:textLabel];
    }
    
    for (int x = 0; x < 3; x++) {
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(yAxisSection.origin.x + 10, 35 + yoffset + (yoffset * x), yAxisSection.size.width, 12)];
        [textLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
        [textLabel setFont:[UIFont systemFontOfSize:10 weight:UIFontWeightRegular]];
        [textLabel setText:[NSString stringWithFormat:@"%d bpm", x]];
        [self addSubview:textLabel];
    }
    
}

@end
