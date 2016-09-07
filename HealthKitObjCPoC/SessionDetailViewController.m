//
//  SessionDetailViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/29/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SessionDetailViewController.h"
#import "Utility.h"

@interface SessionDetailViewController ()

@end

@implementation SessionDetailViewController


@synthesize sleepSession;
@synthesize sleepSessionLabel;
@synthesize inBedLabel;
@synthesize sleepLabel;
@synthesize wakeLabel;
@synthesize outBedLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDateFormatter *timeFormatter = [Utility dateFormatterForTimeLabels];
    NSMutableArray *inBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.inBed];
    NSMutableArray *sleepArray = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.sleep];
    NSMutableArray *wakeArray = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.wake];
    NSMutableArray *outBedArray = [NSKeyedUnarchiver unarchiveObjectWithData:sleepSession.outBed];
    
    sleepSessionLabel.text = sleepSession.name;
    inBedLabel.text = [timeFormatter stringFromDate:[inBedArray firstObject]];
    sleepLabel.text = [timeFormatter stringFromDate:[sleepArray firstObject]];
    wakeLabel.text = [timeFormatter stringFromDate:[wakeArray firstObject]];
    outBedLabel.text = [timeFormatter stringFromDate:[outBedArray firstObject]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
