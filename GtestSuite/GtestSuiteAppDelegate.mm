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
    self.viewController = [[GtestSuiteViewController alloc]
                           initWithNibName:@"GtestSuiteViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    // Find file "options.plist" in the application bundle
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"options" ofType:@"plist"];
    NSDictionary *options = [[NSDictionary alloc]
                             initWithContentsOfFile:plistPath];
    NSString * logFile = [options objectForKey:@"LOG_FILE"];

    // Redirect logs to this file
    [self redirectNSLog:logFile];

    return YES;
}

/*
 * Redirects logging from NSLog to the log file specified in options.plist
 */
- (BOOL)redirectNSLog:(NSString *)logFile
{
    //[@"" writeToFile:logFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    id fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
    if (!fileHandle)
    {
        /*Create the file if it does not exist */
        NSLog(@"Creating log file");
        [@"" writeToFile:logFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
        //return NSLog(@"Opening log failed"), NO;
    }
    [fileHandle seekToEndOfFile];
    
    // Redirect stderr
    NSLog(@"Redirecting NSLog to log file");
    int err = dup2([fileHandle fileDescriptor], STDERR_FILENO);
    if (!err)
        return NSLog(@"Couldn't redirect NSLog"), NO;
    
    // Redirect stdout
    err = dup2([fileHandle fileDescriptor], 1);
    if (!err)
        return NSLog(@"Couldn't redirect stdout"), NO;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
