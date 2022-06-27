//
//  DataHelper.m
//  DistanceDemo
//
//  Created by Shubham Bairagi on 19/06/22.
//

#import "DataHelper.h"

@implementation DataHelper

-(void)start {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"is_sdk_running"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /* Do stuffs */
}

-(void)stop {
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"is_sdk_running"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    /* Do stuffs */
}

-(BOOL)isSdkRunning {
    
    BOOL isRunning = [[NSUserDefaults standardUserDefaults] boolForKey:@"is_sdk_running"];

    return isRunning;
}


@end
