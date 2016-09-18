//
//  SessionDetailTableViewCell.h
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 9/17/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SessionDetailTableViewCell : UITableViewCell

@property (weak, nonatomic, readonly) IBOutlet UILabel *eventTitleLabel;
@property (weak, nonatomic, readonly) IBOutlet UILabel *eventTimeLabel;

@end
