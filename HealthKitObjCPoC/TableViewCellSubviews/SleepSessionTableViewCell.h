//
//  SleepSessionTableViewCell.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/5/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SleepSessionTableViewCell : UITableViewCell

@property (weak, nonatomic, readonly) IBOutlet UILabel *sessionLabel;
@property (weak, nonatomic, readonly) IBOutlet UILabel *sleepStartLabel;
@property (weak, nonatomic, readonly) IBOutlet UILabel *sessionDurationLabel;
@property (weak, nonatomic, readonly) IBOutlet UIImageView *sleepIconImageView;
@property (weak, nonatomic, readonly) IBOutlet UILabel *sleepEndLabel;
@property (weak, nonatomic, readonly) IBOutlet UIImageView *wakeIconImageView;

@end
