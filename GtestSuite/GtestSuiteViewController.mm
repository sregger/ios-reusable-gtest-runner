//
//  GtestSuiteViewController.mm
//  GtestSuite
//
//  Created by kennward on 04/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import "GtestSuiteViewController.h"
#import "GtestSuiteRunner.h"

@interface GtestSuiteViewController ()

@end

@implementation GtestSuiteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Create and configure the test runner, and start it in another thread
    GtestSuiteRunner * testRunner = [self makeGtestSuiteRunner];
    NSThread* gtestThread = [[NSThread alloc] initWithTarget:testRunner
                                                    selector:@selector(runTests)
                                                      object:nil];
    [gtestThread start];

    // Display timestamps for the start and end of the test suite run
    NSString * startLabelText =
        [@"Tests started: " stringByAppendingString:[self stringDateNow]];
    [startTimestampLabel setText:startLabelText];
    NSString * endLabelText = @"Tests ended: ";
    [endTimestampLabel setText:endLabelText];
}

/*
 * Callback for the test thread to call when test suite has finished.
 */
- (void)testSuiteDidFinish
{
    NSString * endLabelText =
        [@"Tests ended: " stringByAppendingString:[self stringDateNow]];
    [endTimestampLabel setText:endLabelText];
}

- (NSString *)stringDateNow
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSDate * now = [[NSDate alloc] init];
    return [dateFormatter stringFromDate:now];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 * Creates a GtestSuiteRunner and configures it with options from a plist file.
 */
- (GtestSuiteRunner *)makeGtestSuiteRunner
{
    // Find file "options.plist" in the application bundle
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"options" ofType:@"plist"];
    NSDictionary *options = [[NSDictionary alloc]
                             initWithContentsOfFile:plistPath];
    NSLog(@"Dictionary from options.plist: %@", options);
    
    NSString * reportURL      = [options objectForKey:@"HTTP_REPORT_URL"];
    NSString * gtestFilter    = [options objectForKey:@"GTEST_FILTER"];
    NSString * gtestOutput    = [options objectForKey:@"GTEST_OUTPUT"];
    NSString * iniFile        = [options objectForKey:@"INI_FILE"];
    NSString * iniFileSection = [options objectForKey:@"INI_FILE_SECTION"];
    NSString * csfInstruments = [options objectForKey:@"CSF_INSTRUMENTS"];
    NSString * testDataLoc    = [options objectForKey:@"TEST_DATA_LOC"];
    
    // Use options to configure the test runner
    GtestSuiteRunner * gsr = [[GtestSuiteRunner alloc] init];
    [gsr setReportURL:reportURL];
    [gsr setGtestFilter:gtestFilter];
    [gsr setGtestOutput:gtestOutput];
    [gsr setIniFile:iniFile];
    [gsr setIniFileSection:iniFileSection];
    [gsr setCsfInstruments:csfInstruments];
    [gsr setTestDataLoc:testDataLoc];
    
    [gsr setDelegate:self];
    
    return gsr;
}

- (void)viewDidUnload {
    startTimestampLabel = nil;
    endTimestampLabel = nil;
    [super viewDidUnload];
}
@end
