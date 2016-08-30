//
//  SessionDetailViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 8/29/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import "SessionDetailViewController.h"

@interface SessionDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end

@implementation SessionDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.testLabel.text = @"Hello World";
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
