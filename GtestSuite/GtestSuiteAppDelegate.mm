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

    // Find file "options.plist" in the application bundle
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"options" ofType:@"plist"];
    NSDictionary *options = [[NSDictionary alloc]
                             initWithContentsOfFile:plistPath];
    NSString * logFile = [options objectForKey:@"LOG_FILE"];

    // Redirect logs to this file
    //[self redirectNSLog:logFile];

    return YES;
}

/*
 * Redirects logging from NSLog to the log file specified in options.plist
 */
- (BOOL)redirectNSLog:(NSString *)logFile
{
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

@end
