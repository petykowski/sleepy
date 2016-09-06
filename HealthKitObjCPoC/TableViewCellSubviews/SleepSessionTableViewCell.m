//
//  SleepSessionTableViewCell.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/5/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SleepSessionTableViewCell.h"

@interface SleepSessionTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *sessionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepStartLabel;
@property (weak, nonatomic) IBOutlet UILabel *sessionDurationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sleepIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *sleepEndLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wakeIconImageView;

@end




@implementation SleepSessionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
