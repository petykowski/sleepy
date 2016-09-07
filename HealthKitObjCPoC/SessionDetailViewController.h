//
//  SessionDetailViewController.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/29/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "session.h"

@interface SessionDetailViewController : UIViewController

@property (nonatomic, strong) session *sleepSession;
@property (weak, nonatomic) IBOutlet UILabel *sleepSessionLabel;
@property (weak, nonatomic) IBOutlet UILabel *inBedLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepLabel;
@property (weak, nonatomic) IBOutlet UILabel *wakeLabel;
@property (weak, nonatomic) IBOutlet UILabel *outBedLabel;

@end
