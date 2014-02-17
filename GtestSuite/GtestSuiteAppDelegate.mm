//
//  GtestSuiteAppDelegate.mm
//  GtestSuite
//
//  Created by kennward on 04/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import "GtestSuiteAppDelegate.h"
#import "GtestSuiteViewController.h"

@implementation GtestSuiteAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.rootViewController = [[GtestSuiteViewController alloc]
                           initWithNibName:@"GtestSuiteViewController" bundle:nil];

    [self.window makeKeyAndVisible];

    return YES;
}

@end
