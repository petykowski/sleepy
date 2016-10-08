//
//  StatisticsTableViewCell.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "StatisticsTableViewCell.h"

@interface StatisticsTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *statisticTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statisticResultLabel;

@end

@implementation StatisticsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
