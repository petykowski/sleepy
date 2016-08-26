//
//  ViewController.m
//  HealthKitObjCPoC
//
//  Created by Sean Petykowski on 1/26/16.
//  Copyright © 2016 Sean Petykowski. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *sleepSession;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSArray *)message replyHandler:(nonnull void (^)(NSDictionary * __nonnull))replyHandler {
    NSArray *sleepData = message;
    
    if (!self.sleepSession) {
        self.sleepSession = [[NSMutableArray alloc] init];
    }
    
    //Use this to update the UI instantaneously (otherwise, takes a little while)
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.sleepSession setArray:sleepData];
    });
    
    NSLog(@"[DEBUG] the contents of array in iOS is: %@", self.sleepSession);
}

@end
