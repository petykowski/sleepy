//
//  StatisticsTableViewCell.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 10/8/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatisticsTableViewCell : UITableViewCell

@property (weak, nonatomic, readonly) IBOutlet UILabel *statisticTitleLabel;
@property (weak, nonatomic, readonly) IBOutlet UILabel *statisticResultLabel;

@end
